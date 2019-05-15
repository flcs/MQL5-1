//+------------------------------------------------------------------+
//|                                                   EAForexAUD.mq5 |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|Changelog:                                                        |
//|v1.00 - Versão inicial baseado no EAArtificialIntelligence.mq5. A |
//|        parte que usava a rede neural perceptron foi substituída  |
//|        por sinais de compra e venda de outros indicadores.       |
//|      - Remoção de todos os parâmetros e métodos que não estão    |
//|        sendo usados.                                             |
//|      - Implementação de sinal de negociação baseado em           |
//|        cruzamento de médias móveis.                              |
//|      - Trailing stop baseado na média móvel curta.               |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property version   "1.00"
#property description "EA projetado para trabalhar no mercado Forex usando os pares de moeda AUD"

//--- Inclusão de arquivos
#include <Trade\Trade.mqh>
//--- Enumerações
enum ENUM_METODO_CALCULO 
  {
   HIGH_LOW=0,// Máxima/Mínima
   OPEN_CLOSE=1 // Abertura/Fechamento
  };

//--- Declaração de classe
CTrade cTrade; // Classe com métodos para negociação

//--- Parâmetros de entrada
input double stopLoss=50; // Stop loss
input double Lots=0.1; // Lots
input int    magicNumber=989898; // Número mágico EA
input int    posicoesAbertas=10; // Máximo de posições abertas
input ENUM_METODO_CALCULO metodoCalculo=HIGH_LOW; // Método de cálculo
input double prejuizoMaximo = 10.0; // Prejuízo máximo de uma posição aberta
input double lucroMaximo = 10.0; // Lucro máximo de uma posição aberta

//--- Variáveis estáticas
static int spread=10;

//--- Handle dos indicadores
int maCurtaHandle,maLongaHandle,dunniganHandle;

//--- Buffers
double maCurtaBuffer[],maLongaBuffer[]; // Armazena os sinais das MAs curta e longa
double vendaBuffer[],compraBuffer[]; // Armazena os sinais de compra e venda de Dunnigan
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//   if(isNewBar())
//     {
//
//      //--- Obtém o valor do spread
//      spread=(int)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);
//
//      //--- Obtém as informações do último preço da cotação
//      MqlTick ultimoPreco;
//      if(!SymbolInfoTick(_Symbol,ultimoPreco))
//        {
//         Print("Erro ao obter a última cotação - error ",GetLastError());
//         return;
//        }

//--- Verifica as posições abertas
//      for(int i=PositionsTotal()-1; i>=0; i--)
//        {
//         if(PositionSelectByTicket(PositionGetTicket(i))
//            && ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE))==POSITION_TYPE_BUY)
//           {
//
//            //--- Verifica se a posição é lucrativa
//            if(PositionGetDouble(POSITION_PROFIT)>0) 
//              { /*
//               Print("Realiza o trailing stop das posições de compra lucrativas");
//               Print("Ticket da posição: ",PositionGetTicket(i));
//               Print("Último Preço ask: ", ultimoPreco.ask);
//               Print("Último Preço bid: ", ultimoPreco.bid);
//               Print("Stop loss da posição: ",NormalizeDouble(PositionGetDouble(POSITION_SL),_Digits));
//               Print("Lucro da posição: ",PositionGetDouble(POSITION_PROFIT));
//               Print("Valor MA curta: ",NormalizeDouble(maCurtaBuffer[1],_Digits));
//               Print("Valor MA longa: ",NormalizeDouble(maLongaBuffer[1],_Digits)); */
//
//               //--- Determina se estamos em uma tendência de alta
//               double mediaMovel=0;
//               if(maCurtaBuffer[1]>maLongaBuffer[1]) 
//                 {
//                  mediaMovel=NormalizeDouble(maCurtaBuffer[1],_Digits);
//
//                  // Realiza o trailiing stop da posição
//                  MarketOrder(ORDER_TYPE_BUY,
//                              TRADE_ACTION_SLTP,
//                              PositionGetDouble(POSITION_PRICE_OPEN),
//                              PositionGetDouble(POSITION_VOLUME),
//                              mediaMovel,
//                              PositionGetDouble(POSITION_TP),
//                              100,
//                              PositionGetTicket(i));
//                 }
//              }
//
//              } else {
//
//            //--- Verifica se a posição é lucrativa
//            if(PositionGetDouble(POSITION_PROFIT)>0) 
//              { /*
//               Print("Realiza o trailing stop das posições de compra lucrativas");
//               Print("Ticket da posição: ",PositionGetTicket(i));
//               Print("Último Preço ask: ", ultimoPreco.ask);
//               Print("Último Preço bid: ", ultimoPreco.bid);
//               Print("Stop loss da posição: ",NormalizeDouble(PositionGetDouble(POSITION_SL),_Digits));
//               Print("Lucro da posição: ",PositionGetDouble(POSITION_PROFIT));
//               Print("Valor MA curta: ",NormalizeDouble(maCurtaBuffer[1],_Digits));
//               Print("Valor MA longa: ",NormalizeDouble(maLongaBuffer[1],_Digits)); */
//
//               //--- Determina se estamos em uma tendência de alta
//               double mediaMovel=0;
//               if(maCurtaBuffer[1]<maLongaBuffer[1]) 
//                 {
//                  mediaMovel=NormalizeDouble(maCurtaBuffer[1],_Digits);
//
//                  // Realiza o trailiing stop da posição
//                  MarketOrder(ORDER_TYPE_BUY,
//                              TRADE_ACTION_SLTP,
//                              PositionGetDouble(POSITION_PRICE_OPEN),
//                              PositionGetDouble(POSITION_VOLUME),
//                              mediaMovel,
//                              PositionGetDouble(POSITION_TP),
//                              100,
//                              PositionGetTicket(i));
//                 }
//              }
//
//           }
//        }

//--- Armazena a quantidade de posições abertas
//--- Caso a conta seja hegding, obtém a informação de PositionsTotal()
//--- Caso a conta seja netting, obtém o volume da posição aberta
//      int totalPosicoes=PositionsTotal();
//      if(((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE))==ACCOUNT_MARGIN_MODE_RETAIL_NETTING)
//        {
//         if(totalPosicoes>0 && PositionSelectByTicket(PositionGetTicket(0)))
//           {
//            totalPosicoes=(int)PositionGetDouble(POSITION_VOLUME);
//           }
//        }
//
//      //--- Obtém o valor do sinal de negociação
//      double sinalNegociacaoValue=sinalNegociacao();
//      double sinalConfirmacao = sinalConfirmacao();
//
//      //--- Verifica a possibilidade de abrir posições longas e curtas
//      //--- Só abre uma nova posição se não tiver extrapolado o limite estabelecido
//      if(totalPosicoes<posicoesAbertas)
//        {
//         if(sinalNegociacaoValue>0)
//           {
//           //--- Neste ponto posso fazer alguma operação prévia antes de confirmar a compra
//           
//           
//           
//           //--- Confirma se pode realizar a compra
//           //if (sinalConfirmacao > 0) {
//               /* Fecha as posições de venda anteriormente aberta */
//               fecharPosicoesAbertas(POSITION_TYPE_SELL);
//               
//               //--- Envia a ordem de compra
//               MarketOrder(ORDER_TYPE_BUY,
//                        TRADE_ACTION_DEAL,
//                        ultimoPreco.ask,
//                        Lots,
//                        0,
//                        0);
//           //}
//            
//              } else if(sinalNegociacaoValue<0) {
//              
//            //--- Neste ponto posso fazer alguma operação prévia antes de confirmar a venda
//              
//            //--- Confirma se pode realizar a venda
//            //if (sinalConfirmacao < 0) {
//               /* Fecha as posições de compra anteriormente aberta */
//               fecharPosicoesAbertas(POSITION_TYPE_BUY);
//            
//               //--- Envia a ordem de venda
//               MarketOrder(ORDER_TYPE_SELL,
//                        TRADE_ACTION_DEAL,
//                        ultimoPreco.bid,
//                        Lots,
//                        0,
//                        0);
//            //}
//            
//           }
//        }
//
//     }

   if(isNewBar()) 
     {

      //--- Obtém o valor do spread
      spread=(int)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);

      //--- Obtém as informações do último preço da cotação
      MqlTick ultimoPreco;
      if(!SymbolInfoTick(_Symbol,ultimoPreco)) 
        {
         Print("Erro ao obter a última cotação - error ",GetLastError());
         return;
        }

      //--- Obtém o valor do perceptron
      double sinalNegociacao = sinalNegociacao();

      //--- Verifica as posições abertas
      for(int i=PositionsTotal()-1; i>=0; i--) 
        {
         if(PositionSelectByTicket(PositionGetTicket(i)) && ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE))==POSITION_TYPE_BUY) 
           {

            //--- Verifica o lucro da posição      
            if(ultimoPreco.bid>(PositionGetDouble(POSITION_SL)+(stopLoss*2+spread)*_Point)
               || PositionGetDouble(POSITION_PROFIT)>=lucroMaximo) 
              {

               if(sinalNegociacao<0) 
                 {
                  //--- Abre uma nova ordem na posição reversa para poder encerrar
                  Print("Ticket #",PositionGetTicket(i)," fechado com o lucro aproximado de ",PositionGetDouble(POSITION_PROFIT));
                  cTrade.PositionClose(PositionGetTicket(i));
                  //MarketOrder(ORDER_TYPE_SELL,
                  //            TRADE_ACTION_DEAL,
                  //            ultimoPreco.bid,
                  //            Lots,
                  //            0,
                  //            0,
                  //            100,
                  //            PositionGetTicket(i));
                    } else {
                  //--- Ajusta o stop loss da posição
                  MarketOrder(ORDER_TYPE_SELL,
                              TRADE_ACTION_SLTP,
                              PositionGetDouble(POSITION_PRICE_OPEN),
                              PositionGetDouble(POSITION_VOLUME),
                              ultimoPreco.ask-stopLoss*_Point,
                              PositionGetDouble(POSITION_TP),
                              100,
                              PositionGetTicket(i));
                 }
                 } else {
               //--- Encerra a posição que alcançou o limite máximo de prejuízo
               if(PositionGetDouble(POSITION_PROFIT)<=(prejuizoMaximo*-1)) 
                 {
                 Print("Ticket #",PositionGetTicket(i)," fechado com o lucro aproximado de ",PositionGetDouble(POSITION_PROFIT));
                  cTrade.PositionClose(PositionGetTicket(i));
                  //MarketOrder(ORDER_TYPE_SELL,
                  //            TRADE_ACTION_DEAL,
                  //            ultimoPreco.bid,
                  //            Lots,
                  //            0,
                  //            0,
                  //            100,
                  //            PositionGetTicket(i));
                 }

              }

              } else {
            //--- Verifica o lucro da posição      
            if(ultimoPreco.ask<(PositionGetDouble(POSITION_SL) -(stopLoss*2+spread)*_Point)
               || PositionGetDouble(POSITION_PROFIT)>=lucroMaximo) 
              {

               if(sinalNegociacao>0) 
                 {
                  //--- Abre uma nova ordem na posição reversa para poder encerrar
                  Print("Ticket #",PositionGetTicket(i)," fechado com o lucro aproximado de ",PositionGetDouble(POSITION_PROFIT));
                  cTrade.PositionClose(PositionGetTicket(i));
                  //MarketOrder(ORDER_TYPE_BUY,
                  //            TRADE_ACTION_DEAL,
                  //            ultimoPreco.ask,
                  //            Lots,
                  //            0,
                  //            0,
                  //            100,
                  //            PositionGetTicket(i));
                    } else {
                  MarketOrder(ORDER_TYPE_BUY,
                              TRADE_ACTION_SLTP,
                              PositionGetDouble(POSITION_PRICE_OPEN),
                              PositionGetDouble(POSITION_VOLUME),
                              ultimoPreco.bid+stopLoss*_Point,
                              PositionGetDouble(POSITION_TP),
                              100,
                              PositionGetTicket(i));
                 }
                 } else {
               //--- Encerra a posição que alcançou o limite máximo de prejuízo
               if(PositionGetDouble(POSITION_PROFIT)<=(prejuizoMaximo*-1)) 
                 {
                 Print("Ticket #",PositionGetTicket(i)," fechado com o lucro aproximado de ",PositionGetDouble(POSITION_PROFIT));
                  cTrade.PositionClose(PositionGetTicket(i));
                  //MarketOrder(ORDER_TYPE_BUY,
                  //            TRADE_ACTION_DEAL,
                  //            ultimoPreco.ask,
                  //            Lots,
                  //            0,
                  //            0,
                  //            100,
                  //            PositionGetTicket(i));
                 }
              }
           }
        }

      //--- Armazena a quantidade de posições abertas
      //--- Caso a conta seja hegding, obtém a informação de PositionsTotal()
      //--- Caso a conta seja netting, obtém o volume da posição aberta
      int totalPosicoes=PositionsTotal();
      if(((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE))==ACCOUNT_MARGIN_MODE_RETAIL_NETTING) 
        {
         if(totalPosicoes>0 && PositionSelectByTicket(PositionGetTicket(0))) 
           {
            totalPosicoes=(int)PositionGetDouble(POSITION_VOLUME);
           }
        }

      //--- Verifica a possibilidade de abrir posições longas e curtas
      //--- Só abre uma nova posição se não tiver extrapolado o limite estabelecido
      if(totalPosicoes<posicoesAbertas) 
        {
         if(sinalNegociacao>0) 
           {
            MarketOrder(ORDER_TYPE_BUY,
                        TRADE_ACTION_DEAL,
                        ultimoPreco.ask,
                        Lots,
                        ultimoPreco.ask-stopLoss*_Point,
                        0);
              } else {
            MarketOrder(ORDER_TYPE_SELL,
                        TRADE_ACTION_DEAL,
                        ultimoPreco.bid,
                        Lots,
                        ultimoPreco.bid+stopLoss*_Point,
                        0);
           }
        }

     }
  }
//+------------------------------------------------------------------+ 
//|  Efetua uma operação de negociação a mercado                     |
//|  Função obtida no seguinte tópico de ajuda:                      |
//|  https://www.mql5.com/pt/docs/event_handlers/ontick              |
//+------------------------------------------------------------------+
bool MarketOrder(ENUM_ORDER_TYPE typeOrder,
                 ENUM_TRADE_REQUEST_ACTIONS typeAction,
                 double price,
                 double volume,
                 double stop,
                 double profit,
                 ulong deviation=100,
                 ulong positionTicket=0)
  {

//--- Declaração e inicialização das estruturas
   MqlTradeRequest tradeRequest; // Envia as requisições de negociação
   MqlTradeResult tradeResult; // Receba o resultado das requisições de negociação
   ZeroMemory(tradeRequest); // Inicializa a estrutura
   ZeroMemory(tradeResult); // Inicializa a estrutura

//--- Popula os campos da estrutura tradeRequest
   tradeRequest.action=typeAction; // Tipo de execução da ordem
   tradeRequest.price=NormalizeDouble(price,_Digits); // Preço da ordem
   tradeRequest.sl=NormalizeDouble(stop,_Digits); // Stop loss da ordem
   tradeRequest.tp=NormalizeDouble(profit,_Digits); // Take profit da ordem
   tradeRequest.symbol= _Symbol; // Símbolo
   tradeRequest.volume = volume; // Volume a ser negociado
   tradeRequest.type= typeOrder; // Tipo de ordem
   tradeRequest.magic=magicNumber; // Número mágico do EA
   tradeRequest.type_filling=ORDER_FILLING_FOK; // Tipo de execução da ordem
   tradeRequest.deviation=deviation; // Desvio permitido em relação ao preço
   tradeRequest.position=positionTicket; // Ticket da posição

//--- Envia a ordem
   if(!OrderSend(tradeRequest,tradeResult))
     {
      //-- Exibimos as informações sobre a falha
      Alert("Não foi possível enviar a ordem. Erro ",GetLastError());
      PrintFormat("Envio de ordem %s %s %.2f a %.5f, erro %d",tradeRequest.symbol,EnumToString(typeOrder),volume,tradeRequest.price,GetLastError());
      return(false);
     }

//-- Exibimos as informações sobre a ordem bem-sucedida
   Alert("Uma nova ordem foi enviada com sucesso! Ticket #", tradeResult.order);
   PrintFormat("Código %u, negociação %I64u, ticket #%I64u", tradeResult.retcode, tradeResult.deal, tradeResult.order);
   return(true);
  }
//+------------------------------------------------------------------+ 
//|  Retorna true quando aparece uma nova barra                      |
//|  Função obtida no seguinte tópico de ajuda:                      |
//|  https://www.mql5.com/pt/docs/event_handlers/ontick              |
//+------------------------------------------------------------------+ 
bool isNewBar()
  {

   static datetime barTime=0; // Armazenamos o tempo de abertura da barra atual
   datetime currentBarTime=iTime(_Symbol,_Period,0); // Obtemos o tempo de abertura da barra zero

   if(barTime!=currentBarTime)//-- Se o tempo de abertura mudar, é porque apareceu uma nova barra
     {
      barTime=currentBarTime;
      return(true); // temos uma nova barra
     }

   return(false); // não há nenhuma barra nova
  }
//+------------------------------------------------------------------+ 
//|  Fecha todas as posições que estão atualmente abertas            |
//+------------------------------------------------------------------+  
void fecharPosicoesAbertas(ENUM_POSITION_TYPE typeOrder) 
  {

/* Fecha a posição anteriormente abertas */
   for(int i=PositionsTotal()-1; i>=0; i--) 
     {
      // Verifica se a posição aberta é uma posição inversa
      if(PositionSelectByTicket(PositionGetTicket(i)) && ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE))==typeOrder) 
        {
         Print("Ticket #",PositionGetTicket(i)," fechado com o lucro aproximado de ",PositionGetDouble(POSITION_PROFIT));
         cTrade.PositionClose(PositionGetTicket(i));
        }
     }
  }
//+------------------------------------------------------------------+
//|  Função responsável por informar se o momento é de abrir uma     |
//|  posição de compra ou venda.                                     |
//|                                                                  |
//|  -1 - Abre uma posição de venda                                  |
//|  +1 - Abre uma posição de compra                                 |
//|   0 - Nenhum posição é aberta                                    |
//+------------------------------------------------------------------+
double sinalNegociacao()
  {

//--- Zero significa que não é pra abrir nenhum posição
   int sinal=0;

//--- Instanciação dos indicadores
   dunniganHandle=iCustom(_Symbol,_Period,"herculeshssj\\IDunnigan.ex5",metodoCalculo);

   if(dunniganHandle<0)
     {
      Alert("Erro ao criar o indicador - erro: ",GetLastError(),"!!!");
      return(sinal);
     }

//--- Copia o valor do indicador para o array
   if(CopyBuffer(dunniganHandle,0,0,2,vendaBuffer)<2
      || CopyBuffer(dunniganHandle,1,0,2,compraBuffer)<2) 
     {

      Print("Erro ao copiar os valores do buffer do indicador Dunnigan - error: ",GetLastError(),"!!!");
      return(sinal);
     }

// Define o array como uma série temporal
   if(!ArraySetAsSeries(vendaBuffer,true))
     {
      Print("Falha ao definir o buffer de venda como série temporal! Erro: ",GetLastError());
      return(sinal);
     }

   if(!ArraySetAsSeries(compraBuffer,true))
     {
      Print("Falha ao definir o buffer de compra como série temporal! Erro: ",GetLastError());
      return(sinal);
     }

//--- Checa a condição e seta o valor para o sinal
   if(compraBuffer[1]>0 && vendaBuffer[1]==0)
     {
      sinal=1; //--- Compra
        } else if(compraBuffer[1]==0 && vendaBuffer[1]>0) {
      sinal=-1; //--- Venda
        } else {
      sinal=0; //--- Não faz nada
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
double sinalConfirmacao()
  {

//--- Zero significa que não é pra abrir nenhum posição
   int sinal=0;

//--- Instanciação dos indicadores
   maCurtaHandle = iMA(_Symbol, _Period, 8, 0, MODE_EMA, PRICE_CLOSE);
   maLongaHandle = iMA(_Symbol, _Period, 20, 0, MODE_SMA, PRICE_CLOSE);

   if(maCurtaHandle<0 || maLongaHandle<0)
     {
      Alert("Erro ao criar os indicadores - erro: ",GetLastError(),"!!!");
      return(sinal);
     }

//--- Copia o valor do indicador para o array
   if(CopyBuffer(maCurtaHandle,0,0,3,maCurtaBuffer)<3)
     {
      Print("Falha ao copiar dados do indicador MA curta! Erro: ",GetLastError());
      return(sinal);
     }

// Define o array como uma série temporal
   if(!ArraySetAsSeries(maCurtaBuffer,true))
     {
      Print("Falha ao definir o buffer MA curta como série temporal! Erro: ",GetLastError());
      return(sinal);
     }

//--- Copia o valor do indicador para o array
   if(CopyBuffer(maLongaHandle,0,0,2,maLongaBuffer)<2)
     {
      Print("Falha ao copiar dados do indicador MA longa! Erro: ",GetLastError());
      return(sinal);
     }

// Define o array como uma série temporal
   if(!ArraySetAsSeries(maLongaBuffer,true))
     {
      Print("Falha ao definir o buffer MA longa como série temporal! Erro: ",GetLastError());
      return(sinal);
     }

//--- Checa a condição e seta o valor para o sinal
   if(maCurtaBuffer[1]>maLongaBuffer[1])
     {
      sinal=1;
        } else if(maCurtaBuffer[1]<maLongaBuffer[1]) {
      sinal=-1;
        } else {
      sinal=0;
     }

//--- Retorna o sinal de negociação
   return(sinal);
  }
//+------------------------------------------------------------------+
