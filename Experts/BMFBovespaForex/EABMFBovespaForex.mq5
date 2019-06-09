//+------------------------------------------------------------------+
//|                                            EABMFBovespaForex.mq5 |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property version   "1.04"

//--- Inclusão de arquivos
#include "HAccount.mqh"
#include "HOrder.mqh"
#include "HStrategy.mqh"
#include "HUtil.mqh"
#include <Trade\Trade.mqh>
#include <herculeshssj\HTrailingStop.mqh>

//--- Variáveis estáticas
static int spread = 10;
static int sinalAConfirmar = 0;

//--- Declaração de classes
CTrade cTrade; // Classe com métodos para negociação obtido das bibliotecas do MetaTrader
CAccount cAccount; // Classe com métodos para obter informações sobre a conta
COrder cOrder; // Classe com métodos utilitários para negociação
CStrategy cStrategy; // Classe para a estratégia de negociação
CUtil cUtil; // Classe com métodos utilitários
CNRTRStop trailingStop; // Classe para stop móvel usando os sinais do indicador NRTR

//--- Parâmetros de entrada
input double                        stopLoss = 0; // Stop loss (pts)
input double                        takeProfit = 0; // Take profit (pts)
input int                           horaAberturaMercado = 0; // Hora de abertura do mercado
input int                           horaFechamentoMercado = 0; // Hora de fechamento do mercado
input double                        lote = 1; // Lote
input int                           magicNumber = 20190524; // Número mágico do EA
input ENUM_TIPO_PREENCHIMENTO_ORDEM tipoPreenchimento = TIPO_TUDO_NADA; // Tipo de execução da ordem
input ENUM_TIPO_MENSAGEM            notificacaoUsuario = CONSOLE; // Notificações para o usuário
input int                           periodoNRTR = 40; // NRTR - Período
input double                        valorKNRTR = 2; // NRTR - K

//+------------------------------------------------------------------+
//| Inicialização do Expert Advisor                                  |
//+------------------------------------------------------------------+
int OnInit() {
   
   //--- Cria um temporizador de 1 minuto
   EventSetTimer(60);
   
   //--- Inicializa a classe para stop móvel
   trailingStop.Init(_Symbol, _Period, magicNumber, true, true, false);
   
   //--- Carrega os parâmetros do indicador NRTR
   if (!trailingStop.setupParameters(periodoNRTR, valorKNRTR)) {
      Alert("Erro na inicialização da classe de stop móvel! Saindo...");
      return(INIT_FAILED);
   }
   
   //--- Inicia o stop móvel para as posições abertas
   trailingStop.on();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Encerramento do Expert Advisor                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   
   //--- Encerra o stop móvel
   trailingStop.Deinit();
   
   //--- Destrói o temporizador
   EventKillTimer();
}

//+------------------------------------------------------------------+
//| Método que recebe os ticks vindo do gráfico                      |
//+------------------------------------------------------------------+
void OnTick() {

   //--- Implementar outro tipo de estratégia para os ticks e candles
   
   //--- Obtém a hora atual
   MqlDateTime horaAtual;
   TimeCurrent(horaAtual);
   
   //--- Verifica se o mercado está aberto para negociações
   if (mercadoAberto(horaAtual)) {
      
      //--- Verifica se tem uma nova barra no gráfico
      if (temNovaBarra()) {
         
         //--- Verifica se possui sinal de negociação a confirmar
         sinalAConfirmar = sinalNegociacao();
         if (sinalAConfirmar != 0) {
            confirmarSinal();         
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Conjuntos de rotinas padronizadas a serem executadas a cada      |
//| minuto (60 segundos).                                            |
//+------------------------------------------------------------------+
void OnTimer() {

   //--- Atualiza os dados do stop móvel
   trailingStop.refresh();
   
   //--- Realiza o stop móvel das posições abertas
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         trailingStop.doStopLoss(PositionGetTicket(i));
      }         
   }

   //--- Dispara uma notificação para a saída escolhida pelo usuário quando o lucro das posições abertas atingir mais de
   //--- que o valor alvo. O valor alvo é proporcional ao tamanho do lote.
   double lucro = cAccount.calcularLucroPosicoesAbertas();
   double valorAlvo = lote * 100 * PositionsTotal();
   
   if (lucro > valorAlvo) {
      cUtil.enviarMensagem(notificacaoUsuario, "ATENÇÃO! Mais de " + AccountInfoString(ACCOUNT_CURRENCY) + " " + DoubleToString(lucro) + " em lucro!!! Corre lá pra pegar ;)");
   }
   
   //--- Dispara uma notificação via push (obrigatoriamente) quando a margem livre for igual
   //--- ou menor que zero
   if (AccountInfoDouble(ACCOUNT_MARGIN_FREE) <= 0) {
      cUtil.enviarMensagem(PUSH, "ATENÇÃO! SEM MARGEM DISPONÍVEL PARA OPERAR!!!");
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
   
   return cStrategy.indicadorTabajara();
   
}

//+------------------------------------------------------------------+
//|  Função responsável por confirmar se o momento é de abrir uma    |
//|  posição de compra ou venda. Esta função é chamada sempre que se |
//|  obter a confirmação do sinal a partir de outro indicador ou     |
//|  outra forma de cálculo.                                         |
//|                                                                  |
//|  -1 - Confirma a abertura da posição de venda                    |
//|  +1 - Confirma a abertura da posição de compra                   |
//|   0 - Informa que nenhuma posição deve ser aberta                |
//|   9 - Cautela positiva - aconselhável aguardar o próximo minuto  |
//|       para poder abrir a posição desejada                        |
//|       abrir a posição desejada                                   |
//|  -9 - Cautela negativa - não é seguro abrir a posição desejada,  |
//|       aconselhável abrir na próxima barra do gráfico.            |
//+------------------------------------------------------------------+
int sinalConfirmacao() {
   
   //--- Implementar
   return(0);
}

//+------------------------------------------------------------------+
//|  Função responsável por confirmar o sinal de negociação indicado |
//|  na abertura da nova barra e abrir uma nova posição de compra/   |
//|  venda de acordo com a tendência do mercado.                     |
//+------------------------------------------------------------------+
void confirmarSinal() {

   if (sinalAConfirmar > 0) {
      //mostrarMensagem("Confirmação de sinal de compra...");
      
      //--- Verifica se existe uma posição de compra já aberta
      if (existePosicoesAbertas(POSITION_TYPE_BUY)) {
         //mostrarMensagem("Existe posição de compra aberta para o símbolo " + _Symbol);
         //--- Substituir com algum código útil
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
      //mostrarMensagem("Confirmação de sinal de venda...");
      
      //--- Verifica se existe uma posição de venda já aberta
      if (existePosicoesAbertas(POSITION_TYPE_SELL)) {
         //mostrarMensagem("Existe posição de venda aberta para o símbolo " + _Symbol);
         //--- Substituir com algum código útil
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
      //mostrarMensagem("Sinal indeterminado, nenhuma posição foi aberta/fechada!");
      //--- Substituir com algum código útil
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
      enviaOrdem(ORDER_TYPE_BUY, TRADE_ACTION_DEAL, ultimoPreco.ask, lote, sl, tp);
   
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
      enviaOrdem(ORDER_TYPE_SELL, TRADE_ACTION_DEAL, ultimoPreco.bid, lote, sl, tp);
    
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