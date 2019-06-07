//+------------------------------------------------------------------+
//|                                            EABMFBovespaForex.mq5 |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|Changelog:                                                        |
//|v1.00 - EA para operação com minicontratos de índice na BM&F      |
//|        Bovespa e para operação com pares de moedas no mercado    |
//|        Forex. O EA foi construído usando todo o conhecimento     |
//|        adquirido sobre linguagem MQL5 até o presente momento.    |
//|        Nesta primeira versão o EA trabalha com o cruzamento de   |
//|        médias móveis para sinais de negociação e controle do     |
//|        prejuízo minuto. Os sinais de negociação e o controle de  |
//|        prejuízo é realizado minuto a minuto, de modo a aproveitar|
//|        ao máximo o começo de novas tendências e sair da operação |
//|        de perda o mais rápido possível.                          |
//|        Todas as opções do EA podem ser desabilitas, bastando     |
//|        informar o valor zero (0) no parâmetro desejado.          |
//|v1.01 - O período (timeframe) do método temNovaBarra() foi        |
//|        parametrizado, assim é possível escolher outros períodos  |
//|        para realizar a verificação de trailing stop. Outro       |
//|        parâmetro incluído foi o tipo de preenchimento das ordens |
//|        para poder se adequar as corretoras Forex. E por fim,     |
//|        é possível escolher qual estratégia de negociação adotar  |
//|        (cruzamento MA ou tendência MA longa).                    |
//|v1.02 - Agora o EA consegue operar em mais de um ativo ao mesmo   |
//|        tempo sem conflito na abertura e no fechamento das        |
//|        posições. Também foi introduzido um delay entre as        |
//|        aberturas e fechamentos das ordens, para minimizar os     |
//|        problemas com o envio de ordens para o servidor MT5 da    |
//|        corretora. E por fim é feito dupla verificação na abertura|
//|        das ordens, sendo efetuado uma abertura quando se tem     |
//|        certeza que a posição contrária já foi fechada.           |
//|v1.03 - Incluído opção para fechar as posições lucrativas quando  |
//|        o close do candle ultrapassar a média móvel nos casos de  |
//|        mudança de tendência. Os principais parâmetros das médias |
//|        móveis foram parametrizados, assim como foi realizado uma |
//|        revisão nos parâmetros existentes. Foi implementado       |
//|        o sinal de negociação do indicador Tabajara e incluído    |
//|        notificações para o usuário alertando sobre altos lucros. |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property version   "1.03"

//--- Inclusão de arquivos
#include "HAccount.mqh"
#include "HOrder.mqh"
#include "HStrategy.mqh"
#include "HUtil.mqh"
#include <Trade\Trade.mqh>

//--- Variáveis estáticas
static int spread = 10;
static int sinalAConfirmar = 0;

//--- Declaração de classes
CTrade cTrade; // Classe com métodos para negociação obtido das bibliotecas do MetaTrader
CAccount cAccount; // Classe com métodos para obter informações sobre a conta
COrder cOrder; // Classe com métodos utilitários para negociação
CStrategy cStrategy; // Classe mãe para as estratégias de negociação
CUtil cUtil; // Classe com métodos utilitários

//--- Parâmetros de entrada
input double                        trailingStop = 0; // Trailing stop (pts)
input double                        prejuizoMaximo = 0; // Prejuízo máximo ($)
input ENUM_TIMEFRAMES               periodoBarra = PERIOD_M1; // Checagem de nova barra 
input TIPO_ESTRATEGIA               tipoSinalNegociacao = CRUZAMENTO_MEDIA_MOVEL; // Sinal de negociação
input int                           periodoMACurta = 8; // Período MA curta
input int                           periodoMALonga = 15; // Período MA longa
input ENUM_MA_METHOD                metodoMACurta = MODE_EMA; // Método MA curta
input ENUM_MA_METHOD                metodoMALonga = MODE_SMA; // Método MA longa
input ENUM_SIM_NAO                  fecharNoRompimento = NAO; // Fechar no rompimento
input ENUM_TIPO_MENSAGEM            notificacaoUsuario = CONSOLE; // Notificações para o usuário
//--- Desde ponto em diante incluir os parâmetros considerados definitivos
input double                        stopLoss = 0; // Stop loss (pts)
input double                        takeProfit = 0; // Take profit (pts)
input int                           horaAberturaMercado = 0; // Hora de abertura do mercado
input int                           horaFechamentoMercado = 0; // Hora de fechamento do mercado
input double                        Lots = 1; // Lots
input int                           magicNumber = 20190524; // Número mágico do EA
input ENUM_TIPO_PREENCHIMENTO_ORDEM tipoPreenchimento = TIPO_TUDO_NADA; // Tipo de execução da ordem

//+------------------------------------------------------------------+
//| Inicialização do Expert Advisor                                  |
//+------------------------------------------------------------------+
int OnInit() {

   //--- Inicializa as variáveis das estratégias
   cStrategy.periodoMACurta = periodoMACurta;
   cStrategy.periodoMALonga = periodoMALonga;
   cStrategy.metodoMACurta = metodoMACurta;
   cStrategy.metodoMALonga = metodoMALonga;
   
   //--- Cria um temporizador de 1 minuto
   EventSetTimer(60);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Encerramento do Expert Advisor                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   
   //--- Destrói o temporizador
   EventKillTimer();
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
         
      //--- Verifica se temos uma nova barra no gráfico
      if (temNovaBarra()) {
      
         //--- Verifica se possui sinal de negociação a confirmar
         sinalAConfirmar = sinalNegociacao();
         if (sinalAConfirmar != 0) {
            confirmarSinal();
         }
         /*
         //--- Verifica se foi marcado para fechar as posições no rompimento da MA Longa
         if (fecharNoRompimento == SIM
               && (existePosicoesAbertas(POSITION_TYPE_BUY) || existePosicoesAbertas(POSITION_TYPE_SELL))
               && PositionSelect(_Symbol) ) {
               
            mostrarMensagem("Valor da MA longa: " + DoubleToString(cStrategy.valorMALonga));
            
            //--- Traz o valor close da barra atual
            double closeBuffer[];
            if (CopyClose(_Symbol, _Period, 0, 1, closeBuffer) < 1) {
               mostrarMensagem("Falha ao copiar os valores para o buffer! Erro " + IntegerToString(GetLastError()));
            }
            mostrarMensagem("Valor close da barra atual: " + DoubleToString(closeBuffer[0]));
            
            //--- Caso exista posição de compra aberta, avalia se o close da barra atual 
            //--- é menor que a MA
            if (existePosicoesAbertas(POSITION_TYPE_BUY) && PositionGetDouble(POSITION_PROFIT) > 0) { 
               
               if (closeBuffer[0] < cStrategy.valorMALonga) {
                  //--- Fecha as posições de compra
                  fecharPosicoesAbertas(POSITION_TYPE_BUY);
               }
               
            } else if (existePosicoesAbertas(POSITION_TYPE_SELL) && PositionGetDouble(POSITION_PROFIT) > 0) {
            
               if ( closeBuffer[0] > cStrategy.valorMALonga) {
                  //--- Fecha as posições de venda
                  fecharPosicoesAbertas(POSITION_TYPE_SELL);
               }
            
            }
         }
            
         //--- Variável para contabilizar o prejuízo acumulado
         double prejuizo = 0;
         
         //--- Itera as posições abertas realizando o trailing stop das lucrativas
         for (int i = PositionsTotal() - 1; i >= 0; i--) {
            if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetDouble(POSITION_PROFIT) > 0) {
               
               if (((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)) == POSITION_TYPE_BUY 
                     && trailingStop > 0 && stopLoss > 0) {
                  
                  mostrarMensagem("Lucro da posição de compra: " + DoubleToString(PositionGetDouble(POSITION_PROFIT)));
                  mostrarMensagem("Realizando o trailing stop das posições de compra....");
                  
                  enviaOrdem(ORDER_TYPE_BUY,
                     TRADE_ACTION_SLTP,
                     PositionGetDouble(POSITION_PRICE_OPEN),
                     PositionGetDouble(POSITION_VOLUME),
                     PositionGetDouble(POSITION_SL) + trailingStop * _Point,
                     PositionGetDouble(POSITION_TP),
                     100,
                     PositionGetTicket(i)); 
                  
               } else if (((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)) == POSITION_TYPE_SELL 
                     && trailingStop > 0 && stopLoss > 0) {
                  
                  mostrarMensagem("Lucro da posição de venda: " + DoubleToString(PositionGetDouble(POSITION_PROFIT)));
                  mostrarMensagem("Realizando o trailing stop das posições de venda....");
                  
                  enviaOrdem(ORDER_TYPE_SELL,
                     TRADE_ACTION_SLTP,
                     PositionGetDouble(POSITION_PRICE_OPEN),
                     PositionGetDouble(POSITION_VOLUME),
                     PositionGetDouble(POSITION_SL) - trailingStop * _Point,
                     PositionGetDouble(POSITION_TP),
                     100,
                     PositionGetTicket(i));
               }
            } else {
               //--- Contabiliza o prejuízo das posições abertas
               if (PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetDouble(POSITION_PROFIT) < 0){
                  prejuizo += MathAbs(PositionGetDouble(POSITION_PROFIT));
               }
            }
         }
         
         //--- Encerra todas as posições caso o prejuízo tenha alcançado o máximo permitido,
         //--- independente de haver posições lucrativas
         if (prejuizoMaximo > 0 && prejuizo >= prejuizoMaximo) {
            cUtil.enviarMensagem(PUSH, "Prejuízo máximo de " + DoubleToString(prejuizo) + ". Posições fechadas!");
            fecharTodasPosicoes();
         }
         */         
      }
   } 
   
}

//+------------------------------------------------------------------+
//| Conjuntos de rotinas padronizadas a serem executadas a cada      |
//| minuto (60 segundos).                                            |
//+------------------------------------------------------------------+
void OnTimer() {
   
   //--- Dispara uma notificação via push quando o lucro das posições abertas atingir mais de
   //--- que o valor alvo. O valor alvo é proporcional ao tamanho do lote.
   double lucro = cAccount.calcularLucroPosicoesAbertas();
   double valorAlvo = Lots * 100 * PositionsTotal();
   
   if (lucro > valorAlvo) {
      cUtil.enviarMensagem(notificacaoUsuario, "ATENÇÃO! Mais de " + AccountInfoString(ACCOUNT_CURRENCY) + " " + DoubleToString(lucro) + " em lucro!!! Corre lá pra pegar ;)");
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
            StringSubstr(EnumToString(periodoBarra), 7), TimeToString(TimeCurrent(), TIME_SECONDS));
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
   
   //--- Determina o tipo de preenchimento da ordem
   ENUM_ORDER_TYPE_FILLING tipo;
   switch(tipoPreenchimento) {      
      case TIPO_TUDO_PARCIAL: tipo = ORDER_FILLING_IOC; break;
      case TIPO_RETORNAR: tipo = ORDER_FILLING_RETURN; break;
      default: tipo = ORDER_FILLING_FOK; break;
   }
   
   //--- Popula os campos da estrutura tradeRequest
   tradeRequest.action = typeAction; // Tipo de execução da ordem
   tradeRequest.price = NormalizeDouble(price, _Digits); // Preço da ordem
   tradeRequest.sl = NormalizeDouble(stop, _Digits); // Stop loss da ordem
   tradeRequest.tp = NormalizeDouble(profit, _Digits); // Take profit da ordem
   tradeRequest.symbol = _Symbol; // Símbolo
   tradeRequest.volume = volume; // Volume a ser negociado
   tradeRequest.type = typeOrder; // Tipo de ordem
   tradeRequest.magic = magicNumber; // Número mágico do EA
   tradeRequest.type_filling = tipo; // Tipo de execução da ordem
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
   
   switch (tipoSinalNegociacao) {
      case CRUZAMENTO_MEDIA_MOVEL: return cStrategy.cruzamentoMediaMovel(); break;
      case TENDENCIA_MA_LONGA: return cStrategy.tendenciaMALonga(); break;
      case TABAJARA: return cStrategy.indicadorTabajara(); break;
      default: return(0);
   }
}

//+------------------------------------------------------------------+
//|  Função responsável por confirmar o sinal de negociação indicado |
//|  na abertura da nova barra e abrir uma nova posição de compra/   |
//|  venda de acordo com a tendência do mercado.                     |
//+------------------------------------------------------------------+
void confirmarSinal() {

   if (sinalAConfirmar > 0) {
      mostrarMensagem("Confirmação de sinal de compra...");
      
      //--- Verifica se existe uma posição de compra já aberta
      if (existePosicoesAbertas(POSITION_TYPE_BUY)) {
         mostrarMensagem("Existe posição de compra aberta para o símbolo " + _Symbol);
      } else {
         
         //--- Verifica se existe uma posição de venda já aberta para poder encerrar
         if (existePosicoesAbertas(POSITION_TYPE_SELL)) {
            //--- Fecha a posição de venda aberta
            fecharPosicoesAbertas(POSITION_TYPE_SELL);
            
            //--- Introduz um pequeno delay antes de prosseguir
            Sleep(1000);
         }
         
         //--- Confere se a posição contrária foi realmente fechada
         if (!existePosicoesAbertas(POSITION_TYPE_SELL)) {
            //--- Abre a nova posição de compra
         realizarNegociacao(ORDER_TYPE_BUY);
         }
         
      }
      
   } else if (sinalAConfirmar < 0) {
      mostrarMensagem("Confirmação de sinal de venda...");
      
      //--- Verifica se existe uma posição de venda já aberta
      if (existePosicoesAbertas(POSITION_TYPE_SELL)) {
         mostrarMensagem("Existe posição de venda aberta para o símbolo " + _Symbol);
      } else {
         
         //--- Verifica se existe uma posição de compra já aberta para poder encerrar
         if (existePosicoesAbertas(POSITION_TYPE_BUY)) {
            //--- Fecha a posição de compra aberta
            fecharPosicoesAbertas(POSITION_TYPE_BUY);
            
            //--- Introduz um pequeno delay antes de prosseguir
            Sleep(1000);
         }
         
         //--- Confere se a posição contrária foi realmente fechada
         if (!existePosicoesAbertas(POSITION_TYPE_BUY)) {
         
            //--- Abre a nova posição de venda
            realizarNegociacao(ORDER_TYPE_SELL);
         }
         
      }
      
   } else {
      mostrarMensagem("Sinal indeterminado, nenhuma posição foi aberta/fechada!");
   }
   
   //--- Por fim zera o sinal a confirmar
   sinalAConfirmar = 0;
}
   
//+------------------------------------------------------------------+
//|  Função responsável por realizar a negociação propriamente dita, |
//|  obtendo as informações do último preço recebido para calcular o |
//|  spread, stop loss e take profit da ordem a ser enviada.         |
//+------------------------------------------------------------------+   
void realizarNegociacao(ENUM_ORDER_TYPE tipoOrdem) {

   //--- Obtém o valor do spread
   spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   
   //--- Obtém as informações do último preço da cotação
   MqlTick ultimoPreco;
   if (!SymbolInfoTick(_Symbol, ultimoPreco)) {
      Print("Erro ao obter a última cotação! - Erro ", GetLastError());
      return;
   }
   
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
}

//+------------------------------------------------------------------+ 
//|  Fecha todas as posições que estão atualmente abertas            |
//+------------------------------------------------------------------+  
void fecharTodasPosicoes() {
   
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      Print("Ticket #", PositionGetTicket(i), " do símbolo ", _Symbol, " fechado com o lucro/prejuízo aproximado de ", PositionGetDouble(POSITION_PROFIT));
      cTrade.PositionClose(PositionGetTicket(i));
   }
}

//+------------------------------------------------------------------+ 
//|  Fecha todas as posições que estão atualmente abertas            |
//+------------------------------------------------------------------+  
void fecharPosicoesAbertas(ENUM_POSITION_TYPE typeOrder) {
   
   /* Fecha a posição anteriormente abertas */
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      // Verifica se a posição aberta é uma posição inversa
      if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol
         && ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)) == typeOrder) {
         Print("Ticket #", PositionGetTicket(i), " do símbolo ", _Symbol, " fechado com o lucro/prejuízo aproximado de ", PositionGetDouble(POSITION_PROFIT));
         cTrade.PositionClose(PositionGetTicket(i));
      }
   }
}  

//+------------------------------------------------------------------+ 
//|  Verifica se existe posição aberta para o símbolo atualmente     |
//|  selecionado. Retorna false caso não tenha nenhuma posição aberta|
//|  para o tipo de posição informado.                               |
//+------------------------------------------------------------------+
bool existePosicoesAbertas(ENUM_POSITION_TYPE tipoPosicao) {
   int contadorCompra = 0;
   int contadorVenda = 0;
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         if ( ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)) == POSITION_TYPE_BUY ) {
            contadorCompra++;
         } else {
            contadorVenda++;
         }
      }
   }
   
   if (tipoPosicao == POSITION_TYPE_BUY && contadorCompra > 0) {
      return(true);
   }
   if (tipoPosicao == POSITION_TYPE_SELL && contadorVenda > 0) {
      return(true);
   }
   
   return(false);
}

void mostrarMensagem(string mensagem) {
   if (MQL5InfoInteger(MQL5_DEBUGGING) || MQL5InfoInteger(MQL5_DEBUG) || MQL5InfoInteger(MQL5_TESTER) || MQL5InfoInteger(MQL5_TESTING)) {
      Print(mensagem);
   }
}
//+------------------------------------------------------------------+