//+------------------------------------------------------------------+
//|                                           EATudoOuNadaWINx19.mq5 |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|Changelog:                                                        |
//|v1.00 - Versão inicial baseado no EADunniganNRTRIniciante         |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property version   "1.00"
#property description "EA baseado no EADunniganNRTRIniciante para operar unicamente com minicontrato de índice no BM&F Bovespa. O foco do EA é obter o máximo de lucro possível, e para isso ele fecha posições de compra/venda e abre nova posição inversa de acordo com os sinas do indicador de Dunnigan. Não existe stop loss/take profit nas ordens, portanto é ESSENCIAL ter margem financeira suficiente para suportar grandes perdas."

//--- Include files
#include <Trade\Trade.mqh>

//-- Enumerations
enum ENUM_METODO_CALCULO {
   HIGH_LOW = 0, // Máxima/Mínima
   OPEN_CLOSE = 1 // Abertura/Fechamento
};

//--- input parameters
input int      EA_Magic=38402;   // EA Magic Number
input double   Lot=1.0;          // Lots to Trade
input ENUM_METODO_CALCULO metodoCalculo = HIGH_LOW; // Método de cálculo

//--- other global parameters
int dunniganHandle; // Handle para o indicador Dunnigan
double buyValue[], sellValue[]; // Armazena os sinais de compra e venda
CTrade cTrade; // Classe com métodos para negociação
ENUM_ACCOUNT_MARGIN_MODE marginMode; // Determina o tipo de margem da conta: netting ou hedging

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   //--- Obtém o handle para o indicador Dunnigan
   dunniganHandle = iCustom(_Symbol, _Period, "herculeshssj\\IDunnigan.ex5", metodoCalculo);
   
   if (dunniganHandle < 0) {
      Alert("Error creating handles for indicators - error: ", GetLastError(), "!!!");
      return(INIT_FAILED);
   }
   
   //-- Identifica o tipo de margem da conta
   marginMode = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   if (marginMode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING) {
      Print("*** Este EA só trabalha com conta netting! Saindo... ***");
      return(INIT_FAILED);
   }
   
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   IndicatorRelease(dunniganHandle);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
   // Do we have enough bars to work with?
   if (Bars(_Symbol, _Period) < 60) // if total bars is less than 60 bars
   {
      Alert("We have less than 60 bars, EA will now exit!!!");
      return;
   }
   
   /*
      We will use the static oldTime variable to serve the bar time.
      At each OnTick() execution we will check the current bar time with the saved one.
      If the bar time isn't equal to the saved time, it indicates that we have a new tick.
   */
   static datetime oldTime;
   datetime newTime[1];
   bool isNewBar = false;
   
   // Coping the last bar time to the element newTime[0]
   int copied = CopyTime(_Symbol, _Period, 0, 1, newTime);
   if (copied > 0) // OK, the data has been copied successfully
   {
      if (oldTime != newTime[0]) // if old time isn't equal to new bar time
      {
         isNewBar = true; // if it isn't a first call, the new bar has appeared
         if (MQL5InfoInteger(MQL5_DEBUGGING))
         {
            Print("We have new bar here ", newTime[0], " old time was ", oldTime);
         }
         oldTime = newTime[0];
      }
   }
   else 
   {
      Alert("Error in copying historical times data, error = ", GetLastError());
      return;
   }
   
   //--- EA should only check for new trade if we have a new bar
   if (isNewBar == false)
   {
      return;
   }
   
   //--- Do we have enough bars to work with?
   int myBars = Bars(_Symbol, _Period);
   if (myBars < 60) // if total bars is less than 60 bars
   {
      Alert("We have less than 60 bars, EA will now exit!!!");
      return;
   }
   
   //--- Define some MQL5 structs we will use for our trade
   MqlTick latestPrice; // To be used for getting recent/lastest price quotes
   MqlTradeRequest tradeRequest; // To be used for sending our trade requests
   MqlTradeResult tradeResult; // To be used to get our trade results
   ZeroMemory(tradeRequest); // Initialization of tradeRequest struct
   
   //--- Get the last price quote using the MQL5 MqlTick struct
   if (!SymbolInfoTick(_Symbol, latestPrice))
   {
      Alert("Error getting the latest price quote - error: ", GetLastError(), "!!!");
      return;
   }
   
   //--- Copy the new values of our indicators to buffers (arrays) using the handle
   if (CopyBuffer(dunniganHandle, 0, 0, BarsCalculated(dunniganHandle), sellValue) < 0 
         || CopyBuffer(dunniganHandle, 1, 0, BarsCalculated(dunniganHandle), buyValue) < 0) {
      
      Alert("Erro ao copiar os valores do buffer do indicador - error: ", GetLastError(), "!!!");
      return;
   }
   
   // Invertendo os arrays
   ArrayReverse(sellValue, 0, WHOLE_ARRAY);
   ArrayReverse(buyValue, 0, WHOLE_ARRAY);
   
   // We have no errors, so continue
   
   // Verifica se existe preço de compra disponível no buffer do indicador
   if (buyValue[1] > 0)
   {
      //-- Fecha todas as posições abertas
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         cTrade.PositionClose(PositionGetTicket(i));
      }
      
      tradeRequest.action = TRADE_ACTION_DEAL; // immediate order execution
      tradeRequest.price = NormalizeDouble(latestPrice.ask, _Digits); // latest ask price      
      tradeRequest.symbol = _Symbol; // current pair
      tradeRequest.volume = Lot; // number of lots to trade
      tradeRequest.magic = EA_Magic; // Order Magic Number
      tradeRequest.type = ORDER_TYPE_BUY; // Buy order
      tradeRequest.type_filling = ORDER_FILLING_FOK; // Order execution type
      tradeRequest.deviation = 100; // Deviation from current price
      //--- Send order
      bool result = OrderSend(tradeRequest, tradeResult);
      
      // Get the result code
      if (tradeResult.retcode == 10009 || tradeResult.retcode == 10008) {
         Alert("A Buy order has been successfully places with Ticket #", tradeResult.order, "!!!");
      } else {
         Alert("The Buy order request could not be completed - error: ", GetLastError());
         ResetLastError();
         return;
      }
      
      return; 
   }
   
   // Verifica se existe preço de venda disponível no buffer do indicador
   if (sellValue[1] > 0)
   {
   
      //-- Fecha todas as posições abertas
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         cTrade.PositionClose(PositionGetTicket(i));
      }
      
      tradeRequest.action = TRADE_ACTION_DEAL; // immediate order execution
      tradeRequest.price = NormalizeDouble(latestPrice.bid, _Digits); // latest ask price
      tradeRequest.symbol = _Symbol; // current pair
      tradeRequest.volume = Lot; // number of lots to trade
      tradeRequest.magic = EA_Magic; // Order Magic Number
      tradeRequest.type = ORDER_TYPE_SELL; // Sell order
      tradeRequest.type_filling = ORDER_FILLING_FOK; // Order execution type
      tradeRequest.deviation = 100; // Deviation from current price
      //--- Send order
      bool result = OrderSend(tradeRequest, tradeResult);
      
      // Get the result code
      if (tradeResult.retcode == 10009 || tradeResult.retcode == 10008) {
         Alert("A Sell order has been successfully places with Ticket #", tradeResult.order, "!!!");
      } else {
         Alert("The Sell order request could not be completed - error: ", GetLastError());
         ResetLastError();
         return;
      }
      
      return;  
   }
   
  }
//+------------------------------------------------------------------+