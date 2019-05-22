//+------------------------------------------------------------------+
//|                                                   EABmfForex.mq5 |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|Changelog:                                                        |
//|v1.00 - EA para operação com minicontratos de índice na BM&F      |
//|        Bovespa e para operação com pares de moedas no mercado    |
//|        Forex. O EA foi construído usando todo o conhecimento     |
//|        adquirido sobre linguagem MQL5 até o presente momento.    |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property version   "1.00"

//--- Inclusão de arquivos
#include <herculeshssj\HAccount.mqh>
#include <herculeshssj\HOrder.mqh>
#include <herculeshssj\HStrategy.mqh>
#include <Trade\Trade.mqh>

//--- Enumerações
enum ENUM_METODO_CALCULO {
   HIGH_LOW = 0, // Máxima/Mínima
   OPEN_CLOSE = 1 // Abertura/Fechamento
};

//--- Variáveis estáticas
static int spread = 10;
static int sinalAConfirmar = 0;

//--- Declaração de classe
CTrade cTrade; // Classe com métodos para negociação obtido das bibliotecas do MetaTrader
CAccount cAccount; // Classe com métodos para obter informações sobre a conta
COrder cOrder; // Classe com métodos utilitários para negociação
CStrategy cStrategy; // Classe mãe para as estratégias de negociação

//--- Handle dos indicadores
int dunniganHandle, maHandle, maCurtaHandle;

//--- Buffers
double vendaBuffer[], compraBuffer[]; // Armazena os sinais de compra e venda de Dunnigan
double maBuffer[], maCurtaBuffer[]; // Armazena os valores da média móvel

//--- Parâmetros de entrada
input double stopLoss = 0; // Stop loss
input double takeProfit = 0; // Take profit
input double trailingStop = 0; // Trailing stop
input int    posicoesAbertas = 0; // Máximo de posições abertas
//input double prejuizoMaximo = 10.0; // Prejuízo máximo de uma posição aberta
//input double lucroMaximo = 10.0; // Lucro máximo de uma posição aberta
input ENUM_METODO_CALCULO metodoCalculo = HIGH_LOW; // Método de cálculo Dunnigan
input int    horaAberturaMercado = 0; // Hora de abertura do mercado
input int    horaFechamentoMercado = 0; // Hora de fechamento do mercado
input double Lots = 0.1; // Lots
input int    magicNumber = 19851024; // Número mágico EA

//+------------------------------------------------------------------+
//| Inicialização do EA                                              |
//+------------------------------------------------------------------+
int init() {

   // TODO - Inicializar os indicadores aqui, para evitar várias instanciações
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Encerramento do EA                                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {

   //--- Libera os indicadores
   IndicatorRelease(dunniganHandle);
   IndicatorRelease(maHandle);
   
}

//+------------------------------------------------------------------+
//| Método que recebe os ticks vindo do gráfico                      |
//+------------------------------------------------------------------+
void OnTick() {

   // Obtém a hora atual
   MqlDateTime horaAtual;
   TimeCurrent(horaAtual);
   
   //--- Verifica se o mercado está aberto para negociações
   if (mercadoAberto(horaAtual)) {
   
      //--- Verifica se tem uma nova barra no gráfico
      if (temNovaBarra()) {

         //--- Realiza o fechamento das posições que alcançaram o lucro/prejuízo
         //--- máximos.
         Print("Fazendo o fechamento das posições que alcançaram lucro/prejuízo máximos...");
         
         //--- Obtém o sinal de negociação e salva para poder realizar a confirmação
         sinalAConfirmar = sinalNegociacao();
         
      } else {
         
         //--- Verifica se possui sinal de negociação a confirmar
         if (sinalAConfirmar != 0) {
            confirmarSinal();
         } else {
         
            //--- Realiza o trailing stop das posições lucrativas a cada 2 minutos
            if (temNovaBarraM2()) {
            
               //--- Obtém o sinal da tendência da MA
               int sinalTendencia = sinalConfirmacao();
               
               //--- Itera as posições abertas realizando o trailing stop das lucrativas
               for (int i = PositionsTotal() - 1; i >= 0; i--) {
                  if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetDouble(POSITION_PROFIT) > 0) {
                     
                     if (((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)) == POSITION_TYPE_BUY 
                           && sinalTendencia > 0 && trailingStop > 0) {
                        
                        Print("Lucro da posição de compra: ", PositionGetDouble(POSITION_PROFIT));
                        Print("Realizando o trailing stop das posições de compra....");
                        
                        enviaOrdem(ORDER_TYPE_BUY,
                           TRADE_ACTION_SLTP,
                           PositionGetDouble(POSITION_PRICE_OPEN),
                           PositionGetDouble(POSITION_VOLUME),
                           PositionGetDouble(POSITION_SL) + trailingStop * _Point,
                           PositionGetDouble(POSITION_TP),
                           100,
                           PositionGetTicket(i)); 
                        
                     } else if (((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)) == POSITION_TYPE_SELL 
                           && sinalTendencia < 0 && trailingStop > 0) {
                        
                        Print("Lucro da posição de venda: ", PositionGetDouble(POSITION_PROFIT));
                        Print("Realizando o trailing stop das posições de venda....");
                        
                        enviaOrdem(ORDER_TYPE_SELL,
                           TRADE_ACTION_SLTP,
                           PositionGetDouble(POSITION_PRICE_OPEN),
                           PositionGetDouble(POSITION_VOLUME),
                           PositionGetDouble(POSITION_SL) - trailingStop * _Point,
                           PositionGetDouble(POSITION_TP),
                           100,
                           PositionGetTicket(i));
                     }
                  }
               }
               
               /* A partir desse ponto avalia as posições com prejuízo */
               
            }
         }
      }
 
   } 
   
}

//+------------------------------------------------------------------+ 
//|  Retorna true quando aparece uma nova barra no gráfico           |
//|  Função obtida no seguinte tópico de ajuda:                      |
//|  https://www.mql5.com/pt/docs/event_handlers/ontick              |
//+------------------------------------------------------------------+ 
bool temNovaBarra() {

   static datetime barTime = 0; // Armazenamos o tempo de abertura da barra atual
   datetime currentBarTime = iTime(_Symbol, _Period, 0); // Obtemos o tempo de abertura da barra zero
   
   //-- Se o tempo de abertura mudar, é porque apareceu uma nova barra
   if (barTime != currentBarTime) {
      barTime = currentBarTime;
      if (MQL5InfoInteger(MQL5_DEBUGGING)) {
         //--- Exibimos uma mensagem sobre o tempo de abertura da nova barra
         PrintFormat("%s: nova barra em %s %s aberta em %s", __FUNCTION__, _Symbol,
            StringSubstr(EnumToString(_Period), 7), TimeToString(TimeCurrent(), TIME_SECONDS));
      }
      
      return(true); // temos uma nova barra
   }

   return(false); // não há nenhuma barra nova
}

//+------------------------------------------------------------------+ 
//|  Retorna true quando aparece uma nova barra no gráfico           |
//|  Função obtida no seguinte tópico de ajuda:                      |
//|  https://www.mql5.com/pt/docs/event_handlers/ontick              |
//+------------------------------------------------------------------+ 
bool temNovaBarraM2() {

   static datetime barTimeM2 = 0; // Armazenamos o tempo de abertura da barra atual
   datetime currentBarTime = iTime(_Symbol, PERIOD_M2, 0); // Obtemos o tempo de abertura da barra zero no timeframe M2
   
   //-- Se o tempo de abertura mudar, é porque apareceu uma nova barra
   if (barTimeM2 != currentBarTime) {
      barTimeM2 = currentBarTime;
      if (MQL5InfoInteger(MQL5_DEBUGGING)) {
         //--- Exibimos uma mensagem sobre o tempo de abertura da nova barra
         PrintFormat("%s: nova barra em %s %s aberta em %s", __FUNCTION__, _Symbol,
            StringSubstr(EnumToString(PERIOD_M2), 7), TimeToString(TimeCurrent(), TIME_SECONDS));
      }
      
      return(true); // temos uma nova barra
   }

   return(false); // não há nenhuma barra nova
}

//+------------------------------------------------------------------+ 
//|  Retorna true caso esteja dentro do perído permitido pelo        |
//|  usuário e a corretora para efetuar operações daytrade.          |
//+------------------------------------------------------------------+  
bool mercadoAberto(MqlDateTime &hora) {

   //--- Caso o valor do horário de abertura e fechamento seja zero(0), 
   //--- não tem hora de restrição para operar no mercado
   if (horaAberturaMercado == 0 && horaFechamentoMercado == 0) {
      return(true);
   }
   
   //--- Verifica se o horário atual permite operar
   if (hora.hour >= horaAberturaMercado && hora.hour < horaFechamentoMercado) {
      return(true);
   } else {
      //-- Exclui todas as ordens pendentes
      if (OrdersTotal() > 0) {
         for (int i = OrdersTotal() - 1; i >= 0; i--) {
            cTrade.OrderDelete(OrderGetTicket(i));
         }
      }
      
      //-- Fecha todas as posições abertas
      if (PositionsTotal() > 0) {
         for (int i = PositionsTotal() - 1; i >= 0; i--) {
            cTrade.PositionClose(PositionGetTicket(i));
         }
      }
   }
   
   return(false);
}

//+------------------------------------------------------------------+ 
//|  Efetua uma operação de negociação a mercado                     |
//|  Função obtida no seguinte tópico de ajuda:                      |
//|  https://www.mql5.com/pt/docs/event_handlers/ontick              |
//+------------------------------------------------------------------+
bool enviaOrdem(ENUM_ORDER_TYPE typeOrder,
                 ENUM_TRADE_REQUEST_ACTIONS typeAction,
                 double price,
                 double volume,
                 double stop,
                 double profit,
                 ulong deviation=100,
                 ulong positionTicket=0) {

   //--- Declaração e inicialização das estruturas
   MqlTradeRequest tradeRequest; // Envia as requisições de negociação
   MqlTradeResult tradeResult; // Receba o resultado das requisições de negociação
   ZeroMemory(tradeRequest); // Inicializa a estrutura
   ZeroMemory(tradeResult); // Inicializa a estrutura
   
   //--- Popula os campos da estrutura tradeRequest
   tradeRequest.action = typeAction; // Tipo de execução da ordem
   tradeRequest.price = NormalizeDouble(price, _Digits); // Preço da ordem
   tradeRequest.sl = NormalizeDouble(stop, _Digits); // Stop loss da ordem
   tradeRequest.tp = NormalizeDouble(profit, _Digits); // Take profit da ordem
   tradeRequest.symbol = _Symbol; // Símbolo
   tradeRequest.volume = volume; // Volume a ser negociado
   tradeRequest.type = typeOrder; // Tipo de ordem
   tradeRequest.magic = magicNumber; // Número mágico do EA
   tradeRequest.type_filling = ORDER_FILLING_FOK; // Tipo de execução da ordem
   tradeRequest.deviation = deviation; // Desvio permitido em relação ao preço
   tradeRequest.position = positionTicket; // Ticket da posição
   
   //--- Envia a ordem
   if(!OrderSend(tradeRequest, tradeResult)) {
      //-- Exibimos as informações sobre a falha
      Alert("Não foi possível enviar a ordem! Erro ",GetLastError());
      PrintFormat("Envio de ordem %s %s %.2f a %.5f, erro %d", tradeRequest.symbol, EnumToString(typeOrder), volume, tradeRequest.price, GetLastError());
      return(false);
   }
   
   //-- Exibimos as informações sobre a ordem bem-sucedida
   Alert("Uma nova ordem foi enviada com sucesso! Ticket #", tradeResult.order);
   PrintFormat("Código %u, negociação %I64u, ticket #%I64u", tradeResult.retcode, tradeResult.deal, tradeResult.order);
   return(true);
   
}

//+------------------------------------------------------------------+
//|  Função responsável por informar se o momento é de abrir uma     |
//|  posição de compra ou venda.                                     |
//|                                                                  |
//|  -1 - Abre uma posição de venda                                  |
//|  +1 - Abre uma posição de compra                                 |
//|   0 - Nenhum posição é aberta                                    |
//+------------------------------------------------------------------+
int sinalNegociacao() {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   //--- Instanciação do indicador
   dunniganHandle = iCustom(_Symbol, _Period, "herculeshssj\\IDunnigan.ex5", metodoCalculo);
   
   if(dunniganHandle < 0) {
      Alert("Falha ao criar o indicador! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Copia o valor do indicador para o array
   if(CopyBuffer(dunniganHandle, 0, 0, 2, vendaBuffer) < 2 || CopyBuffer(dunniganHandle, 1, 0, 2, compraBuffer) < 2) {
      Print("Falha ao copiar os valores do buffer do indicador Dunnigan! Erro ", GetLastError());
      return(sinal);
   }
   
   // Define o array como uma série temporal
   if(!ArraySetAsSeries(vendaBuffer, true)) {
      Print("Falha ao definir o buffer de venda como série temporal! Erro ", GetLastError());
      return(sinal);
   }

   if(!ArraySetAsSeries(compraBuffer, true)) {
      Print("Falha ao definir o buffer de compra como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Checa a condição e seta o valor para o sinal
   if(compraBuffer[1] > 0 && vendaBuffer[1] == 0) {
      sinal = 1; //--- Compra
   } else if(compraBuffer[1] == 0 && vendaBuffer[1] > 0) {
      sinal = -1; //--- Venda
   } else {
      sinal = 0; //--- Não faz nada
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
  
}

//+------------------------------------------------------------------+
//|  Função responsável por confirmar se o momento é o ideal para    |
//|  abrir uma posição de compra ou venda.                           |
//|                                                                  |
//|  -1 - Confirma a abertura de uma posição de venda                |
//|  +1 - Confirma a abertura de uma posição de compra               |
//|   0 - Nenhuma posição deve ser aberta                            |
//+------------------------------------------------------------------+
int sinalConfirmacao() {
   
   //--- Zero significa que não é para abrir nenhuma posição
   int sinal = 0;
   
   //--- Instanciação dos indicadores
   maHandle = iMA(_Symbol, _Period, 8, 0, MODE_EMA, PRICE_CLOSE);
   maCurtaHandle = iMA(_Symbol, PERIOD_M2, 20, 0, MODE_SMA, PRICE_CLOSE);
   //maHandle = iMA(_Symbol, _Period, 15, 0, MODE_SMA, PRICE_CLOSE);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (maHandle < 0 || maCurtaHandle < 0) {
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Copia o valor do indicador para o array
   if (CopyBuffer(maHandle, 0, 0, 3, maBuffer) < 3 || 
         CopyBuffer(maCurtaHandle, 0, 0, 3, maCurtaBuffer) < 3) {
      Print("Falha ao copiar dados dos indicadores MA! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define o array como série temporal
   if (!ArraySetAsSeries(maBuffer, true) || !ArraySetAsSeries(maCurtaBuffer, true)) {
      Print("Falha ao definir os buffers MA como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica a MA das barras para determinar a tendência
   if (maBuffer[2] < maBuffer[1] && maCurtaBuffer[2] < maCurtaBuffer[1]) {
      // Tendência de alta
      sinal = 1;
   } else if (maBuffer[2] > maBuffer[1] && maCurtaBuffer[2] > maCurtaBuffer[1]) {
      // Tendência de baixa
      sinal = -1;
   } else {
      // Não operar
      sinal = 0;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
}   


//+------------------------------------------------------------------+
//|  Função responsável por confirmar o sinal de negociação indicado |
//|  na abertura da nova barra e abrir uma nova posição de compra/   |
//|  venda de acordo com a tendência do mercado.                     |
//+------------------------------------------------------------------+
void confirmarSinal() {
      
   int sinalConfirmacao = sinalConfirmacao();
   if (sinalAConfirmar > 0) {
      Print("Confirmação de sinal de compra...");
      
      //--- Confirma o sinal de compra
      if (sinalConfirmacao > 0) {
         Print("Sinal confirmado! Pode comprar!!!!");
         realizarNegociacao(ORDER_TYPE_BUY);
      } else if (sinalConfirmacao < 0) {
         Print("Sinal não confirmado! Compra não realizada");
         //Print("Sinal não confirmado! Sinal invertido!");
         //realizarNegociacao(ORDER_TYPE_SELL);
      } else {
         Print("Nenhuma posição foi aberta!");
      }
      
   } else {
      Print("Confirmação de sinal de venda...");
      
      //--- Confirma o sinal de compra
      if (sinalConfirmacao < 0) {
         Print("Sinal confirmado! Pode vender!!!!");
         realizarNegociacao(ORDER_TYPE_SELL);
      } else if (sinalConfirmacao > 0) {
         Print("Sinal não confirmado! Venda não realizada");
         //Print("Sinal não confirmado! Sinal invertido!");
         //realizarNegociacao(ORDER_TYPE_BUY);
      } else {
         Print("Sinal indeterminado, nenhuma posição foi aberta!");
      }
   }
   
   //--- Por fim zera o sinal a confirmar
   sinalAConfirmar = 0;
}
   
   
void realizarNegociacao(ENUM_ORDER_TYPE tipoOrdem) {

   //--- Obtém o valor do spread
   spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   
   //--- Obtém as informações do último preço da cotação
   MqlTick ultimoPreco;
   if (!SymbolInfoTick(_Symbol, ultimoPreco)) {
      Print("Erro ao obter a última cotação! - Erro ", GetLastError());
   }
   
   //--- Verifica se novas posições podem ser abertas
   //--- Armazena a quantidade de posições abertas
   //--- Caso a conta seja hegding, obtém a informação de PositionsTotal()
   //--- Caso a conta seja netting, obtém o volume da posição aberta
   int totalPosicoes = PositionsTotal();
   if(((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE)) == ACCOUNT_MARGIN_MODE_RETAIL_NETTING) {
      if(totalPosicoes > 0 && PositionSelectByTicket(PositionGetTicket(0))) {
         totalPosicoes=(int)PositionGetDouble(POSITION_VOLUME);
      }
   }
   
   //--- Verifica a possibilidade de abrir posições longas e curtas
   //--- Só abre uma nova posição se não tiver extrapolado o limite estabelecido
   if(posicoesAbertas == 0 || totalPosicoes < posicoesAbertas) {
      if (tipoOrdem == ORDER_TYPE_BUY) {
      
         //--- Calcula o stop loss e take profit
         double sl = 0;
         if(stopLoss > 0) {
            sl = ultimoPreco.ask - stopLoss * _Point;
         }

         double tp = 0;
         if(takeProfit > 0) {
            tp = ultimoPreco.ask + takeProfit * _Point;
         }
         
         //--- Envia a ordem de compra
         enviaOrdem(ORDER_TYPE_BUY, TRADE_ACTION_DEAL, ultimoPreco.ask, Lots, sl, tp);
      
      } else {
      
         //--- Calcula o stop loss e take profit
         double sl = 0;
         if(stopLoss > 0) {
            sl = ultimoPreco.bid + stopLoss * _Point;
         }

         double tp = 0;
         if(takeProfit > 0) {
            tp = ultimoPreco.bid - takeProfit * _Point;
         }
         
         //--- Envia a ordem de venda
         enviaOrdem(ORDER_TYPE_SELL, TRADE_ACTION_DEAL, ultimoPreco.bid, Lots, sl, tp);
       
      } 
   } else {
      Print("Atingido o limite máximo de posições abertas!");
   }

}

//+------------------------------------------------------------------+ 
//|  Fecha todas as posições que estão atualmente abertas            |
//+------------------------------------------------------------------+  
void fecharPosicoesAbertas(ENUM_POSITION_TYPE typeOrder) {
   
   /* Fecha a posição anteriormente abertas */
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      // Verifica se a posição aberta é uma posição inversa
      if (PositionSelectByTicket(PositionGetTicket(i)) && ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)) == typeOrder) {
         Print("Ticket #", PositionGetTicket(i), " fechado com o lucro aproximado de ", PositionGetDouble(POSITION_PROFIT));
         cTrade.PositionClose(PositionGetTicket(i));
      }
   }
} 

//+------------------------------------------------------------------+ 
//|  Fecha todas as posições que estão atualmente abertas            |
//+------------------------------------------------------------------+  
void fecharTodasPosicoes() {
   
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      Print("Ticket #", PositionGetTicket(i), " fechado com o lucro aproximado de ", PositionGetDouble(POSITION_PROFIT));
      cTrade.PositionClose(PositionGetTicket(i));
   }
} 
//+------------------------------------------------------------------+