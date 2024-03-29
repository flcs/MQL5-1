//+------------------------------------------------------------------+
//|                                                  HBMFBovespa.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Arquivo MQH que contém a estratégia para negociação no mercado BM&FBovespa"

//--- Inclusão de arquivos
#include "..\\HStrategy.mqh"

//+------------------------------------------------------------------+
//| Classe CMinicontratoIndice - Cruzamento de Médias Móveis         |
//| exponenciais de 20 e 50 períodos, com confirmação baseado no     |
//| indicador NRTR.                                                  |
//| Sempre que as posições abertas atingirem o lucro alvo, novas     |
//| posições serão abertas para maximixar o lucro.                   |
//+------------------------------------------------------------------+
class CMinicontratoIndice : public CStrategy {

   private:
      int maCurtaHandle;
      int maLongaHandle;

   public:
      //--- Atributos
      double lucroGarantido;
         
      //--- Métodos
      virtual int init(void);
      virtual void release(void);
      virtual int sinalNegociacao(void);
      virtual int sinalConfirmacao(int sinalNegociacao);
      virtual int sinalSaidaNegociacao(int chamadaSaida);  
      
      int onTickBarTimer(void) {
         return(1); // Nova barra
      }    

};

int CMinicontratoIndice::init(void) {
   
   maCurtaHandle = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   maLongaHandle = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (maCurtaHandle < 0 || maLongaHandle < 0) {
      Alert("Erro ao criar os indicadores! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CMinicontratoIndice::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(maCurtaHandle);
   IndicatorRelease(maLongaHandle);
}

int CMinicontratoIndice::sinalNegociacao(void) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double maCurtaBuffer[], maLongaBuffer[]; // Armazena os valores das médias móveis
   
   //--- Copia o valor dos indicadores para seus respectivos buffers
   if (CopyBuffer(maCurtaHandle, 0, 0, 3, maCurtaBuffer) < 3
         || CopyBuffer(maLongaHandle, 0, 0, 3, maLongaBuffer) < 3) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(maCurtaBuffer, true) || !ArraySetAsSeries(maLongaBuffer, true)) {
      Print("Falha ao definir os buffers como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica a MA das barras para determinar a tendência
   if (maCurtaBuffer[2] < maLongaBuffer[1] && maCurtaBuffer[1] > maLongaBuffer[1]) {
      // Tendência em alta
      sinal = 1;
   } else if (maCurtaBuffer[2] > maLongaBuffer[1] && maCurtaBuffer[1] < maLongaBuffer[1]) {
      // Tendência em baixa
      sinal = -1;
   } else {
      // Sem tendência
      sinal = 0;
   }

   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CMinicontratoIndice::sinalConfirmacao(int sinalNegociacao) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   //--- Compara o sinal de negociação com o valor atual de suporte e resistência
   //--- do indicador NRTR
   
   //--- Tendência está a favor?
   if (sinalNegociacao == 1 && trailingStop.trend() == 1) {
      //--- Confirmado o sinal de compra
      sinal = 1;
   } else if (sinalNegociacao == -1 && trailingStop.trend() == -1) {
      //--- Confirmado o sinal de venda
      sinal = -1;
   }
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CMinicontratoIndice::sinalSaidaNegociacao(int chamadaSaida) {

   //--- Obtém o tamanho do tick
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   
   //--- Obtém as informações do último preço da cotação
   MqlTick ultimoPreco;
   if (!SymbolInfoTick(_Symbol, ultimoPreco)) {
      Print("Erro ao obter a última cotação! - Erro ", GetLastError());
      return(-1);
   }
   
   //--- Determina o tamanho do lote
   double lote = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   //--- Verifica se a chamada veio do método OnTimer()
   if (chamadaSaida == 9) {
      
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            
            double lucro = PositionGetDouble(POSITION_PROFIT);
            double valorAlvo = cAccount
               .obterMargemNecessariaParaNovaPosicao(PositionGetDouble(POSITION_VOLUME), 
                  (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE))
               * 0.2; // 20% da margem disponível para abertura
            
            //--- Nos casos que o valorAlvo for menor que um, usa-se volume * 25;
            if (valorAlvo < 1) {
               valorAlvo = PositionGetDouble(POSITION_VOLUME) * 25;
            }
            
            if (lucro > valorAlvo) {
               
               //--- Se o lucro garantido está sendo definido pela primeira vez, o lucro atual será o lucro garantido
               if (this.lucroGarantido == 0) {
                  this.lucroGarantido = lucro;
               } else {
                  //--- Verifica se o lucro ultrapassou 20% do lucro garantido
                  if ( lucro > (this.lucroGarantido * 1.2) ) {
                     //--- Define o novo lucro garantido
                     this.lucroGarantido = lucro;
                     
                     //--- Abre uma nova posição
                     if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                        //--- Ajusta o preço nos casos do tick vier com um valor inválido
                        double preco = ultimoPreco.ask;
                        
                        // Diminui o resto da divisão do preço com o tick size para igualar ao
                        // último múltiplo do valor de tick size
                        if (fmod(preco, tickSize) != 0) {
                           preco = preco - fmod(preco, tickSize);
                        }                        
                     
                        cOrder.enviaOrdem(ORDER_TYPE_BUY, TRADE_ACTION_DEAL, preco, lote, 0, 0);
                     } else {
                     
                        //--- Ajusta o preço nos casos do tick vier com um valor inválido
                        double preco = ultimoPreco.bid;
                        
                        // Diminui o resto da divisão do preço com o tick size para igualar ao
                        // último múltiplo do valor de tick size
                        if (fmod(preco, tickSize) != 0) {
                           preco = preco - fmod(preco, tickSize);
                        }
                        
                        cOrder.enviaOrdem(ORDER_TYPE_SELL, TRADE_ACTION_DEAL, preco, lote, 0, 0);
                     }                  
                     
                  } else if (lucro <= (lucroGarantido * 0.8) ) {
                     // Reseta as variáveis
                     this.lucroGarantido = 0;
                  
                     //--- Encerra a posição aberta
                     string mensagem = "Ticket #" 
                        + IntegerToString(PositionGetTicket(i)) 
                        + " do símbolo " + _Symbol + " fechado com o lucro/prejuízo de " 
                        + DoubleToString(PositionGetDouble(POSITION_PROFIT));
                     cOrder.fecharPosicao(PositionGetTicket(i));
                     cUtil.enviarMensagem(PUSH, mensagem);
                  
                  }
               }
               
            } else if (lucro <= -50) {
               //--- Encerra a posição quando o prejuízo alcançar o limite máximo estabelecido
               string mensagem = "Ticket #" 
                  + IntegerToString(PositionGetTicket(i)) 
                  + " do símbolo " + _Symbol + " fechado com o lucro/prejuízo de " 
                  + DoubleToString(PositionGetDouble(POSITION_PROFIT));
               cOrder.fecharPosicao(PositionGetTicket(i));
               cUtil.enviarMensagem(PUSH, mensagem);
            }
         }         
      }
      
   }

   return(-1);
}

//+------------------------------------------------------------------+

/* Desde ponto em diante ficam as declarações das classes das estratégias
   declaradas neste arquivo MQH
*/

//--- Declaração de classes
CMinicontratoIndice cMiniContratoIndice;

//+------------------------------------------------------------------+