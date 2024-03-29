//+------------------------------------------------------------------+
//|                                                HTrailingStop.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Classe para realizar o stop móvel das posições abertas"

//--- Inclusão de arquivos
#include "HOrder.mqh"

//--- Declaração de classes
COrder cOrder; // Classe com métodos utilitários para negociação

//+------------------------------------------------------------------+
//| Classe CTrailingStop - responsável por mover o stop loss das     |
//| das posições abertas do ativo selecionado.                       |
//+------------------------------------------------------------------+
class CTrailingStop {
   
   protected:
      string m_symbol;              // symbol
      ENUM_TIMEFRAMES m_timeframe;  // timeframe
      bool m_eachtick;              // work on each tick
      bool m_indicator;             // show indicator on chart
      bool m_button;                // show "turn on/off" button
      int m_button_x;               // x coordinate of button
      int m_button_y;               // y coordinate of button
      color m_bgcolor;              // button color
      color m_txtcolor;             // button caption color
      int m_shift;                  // bar shift
      bool m_onoff;                 // turned on/turned off
      int m_handle;                 // indicator handle
      datetime m_lasttime;          // time of trailing stop last execution
      MqlTradeRequest tradeRequest; // trade request struct
      MqlTradeResult tradeResult;   // struct of trade request result
      int m_digits;                 // number of digits after comma for price
      double m_point;               // value of point
      string m_objname;             // button name
      string m_typename;            // name of trailing stop type
      string m_caption;             // button caption
      int m_magic;                  // magic number of expert advisor
      
   public:
      void CTrailingStop() {};            // Constructor
      void ~CTrailingStop() {};           // Constructor
      
      // Initialization of class
      void Init(string symbol, 
                ENUM_TIMEFRAMES timeframe,
                int magicnumber,
                bool eachtick,
                bool indicator,
                bool button,
                int button_x,
                int button_y,
                color bgcolor,
                color txtcolor);
      
      // Start timer
      bool startTimer(void);
      
      // Stop timer
      void stopTimer(void);
      
      // Turn on trailing stop
      void on(void);
      
      // Turn off trailing stop
      void off(void);
        
      // Main method of controlling level of Stop Loss position                    
      //bool doStopLoss(void);
      bool doStopLoss(ulong ticket);
      
      // Method of processing chart events (pressing button to turn on trailing stop)
      void eventHandle(const int id, 
                       const long &lparam, 
                       const double &dparam,
                       const string &sparam);
                       
      // Deinitialization                            
      void Deinit(void);                   
      
      //--- Virtual methods
      
      // Refresh indicator
      virtual bool refresh(){ 
         return(false);
      };
      
      // Setting parameters and loading indicator          
      virtual void setupParameters() { };  
      
      // Trend shown by indicator
      virtual int trend() {
         return(0);
      };           
        
      // Stop Loss value for the Buy position  
      virtual double buyStopLoss() {
         return(0);
      };   
       
      // Stop Loss value for the Sell position
      virtual double sellStopLoss() {
         return(0);
      };   
};

//--- Trailing stop initialization method
void CTrailingStop::Init(string symbol, 
                         ENUM_TIMEFRAMES timeframe,
                         int magicnumber,
                         bool eachtick = true,
                         bool indicator = false,
                         bool button = false,
                         int button_x = 5,
                         int button_y = 15,
                         color bgcolor = Silver,
                         color txtcolor = Blue) {
                         
   //--- Set parameters
   m_symbol = symbol; // symbol
   m_timeframe = timeframe; // timeframe
   m_eachtick = eachtick; // true - work on each tick, false - work once per bar
   m_magic = magicnumber; // EA magic number
   
   //--- Set bar, from which indicator value is used
   if (eachtick) {
      m_shift = 0; // created bar in per tick mode
   } else {
      m_shift = 1; // created bar in per bar mode
   }
   
   m_indicator = indicator; // true - attach indicator to chart
   m_button = button; // true - create button to turn on/turn off trailing stop
   m_button_x = button_x; // x coordinate of button
   m_button_y = button_y; // y coordinate of button
   m_bgcolor = bgcolor; // button color
   m_txtcolor = txtcolor; // button caption color
   
   //--- Get unchanged market history
   m_digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS); // number of digits after comma for price
   m_point = SymbolInfoDouble(m_symbol, SYMBOL_POINT); // value of point
   
   //--- Creating button name and button caption
   m_objname = "CTrailingStop_" + m_typename + symbol; // button name
   m_caption = symbol + " " + m_typename + " Trailing"; // button caption
   
   //--- Filling the trade request struct
   tradeRequest.symbol = m_symbol; // preparing trade request struct, setting symbol
   tradeRequest.action = TRADE_ACTION_SLTP; // preparing trade request struct, setting type of trade action
   
   //-- Creating button
   if (m_button) {
      ObjectCreate(0, m_objname, OBJ_BUTTON, 0, 0, 0); // creating
      ObjectSetInteger(0, m_objname, OBJPROP_XDISTANCE, m_button_x); // setting x coordinate
      ObjectSetInteger(0, m_objname, OBJPROP_YDISTANCE, m_button_y); // setting y coordinate
      ObjectSetInteger(0, m_objname, OBJPROP_BGCOLOR, m_bgcolor); // setting background color
      ObjectSetInteger(0, m_objname, OBJPROP_COLOR, m_txtcolor); // setting caption color
      ObjectSetInteger(0, m_objname, OBJPROP_XSIZE, 120); // setting width
      ObjectSetInteger(0, m_objname, OBJPROP_YSIZE, 15); // setting height
      ObjectSetInteger(0, m_objname, OBJPROP_FONTSIZE, 7); // setting font size
      ObjectSetString(0, m_objname, OBJPROP_TEXT, m_caption); // setting button caption
      ObjectSetInteger(0, m_objname, OBJPROP_STATE, false); // setting button state, turned off by default
      ObjectSetInteger(0, m_objname, OBJPROP_SELECTABLE, false); // user can't select and move button, only click it
      
      ChartRedraw(); // chart redraw
   }
   
   //--- Setting state of trailing stop
   m_onoff = false; // state of trailing stop - turned on/turned off, turned off by default
}

//--- Start timer
bool CTrailingStop::startTimer(void) {
   return(EventSetTimer(1));
}

//--- Stop timer
void CTrailingStop::stopTimer(void) {
   EventKillTimer();
}

//--- Turn on trailing stop
void CTrailingStop::on(void) {
   m_onoff = true;
   if (m_button) {
      // if button is used, it is "pressed"
      if (!ObjectGetInteger(0, m_objname, OBJPROP_STATE)) {
         ObjectSetInteger(0, m_objname, OBJPROP_STATE, true);
      }
   }
}

//--- Turn off trailing stop
void CTrailingStop::off(void) {
   m_onoff = false;
   if (m_button) {
      // if button is used, it is "pressed"
      if (ObjectGetInteger(0, m_objname, OBJPROP_STATE)) {
         ObjectSetInteger(0, m_objname, OBJPROP_STATE, false);
      }
   }
}

//--- Method of tracking button state - turned on/turned off
void CTrailingStop::eventHandle(const int id, 
                                const long &lparam, 
                                const double &dparam,
                                const string &sparam) {
                                
   if (id == CHARTEVENT_OBJECT_CLICK && sparam == m_objname) {
      // there is an event with button
      if (ObjectGetInteger(0, m_objname, OBJPROP_STATE)) {
         this.on(); // turn on
      } else {
         this.off(); // turn off
      }
   }
}

//--- Method of deinitialization
void CTrailingStop::Deinit(void) {

   this.stopTimer(); // stop timer
   IndicatorRelease(m_handle); // release indicator handle
   if (m_button) {
      ObjectDelete(0, m_objname); // delete button
      ChartRedraw(); // chart redraw
   }
   
}

bool CTrailingStop::doStopLoss(ulong ticket) {
   
   if (!m_onoff) {
      return(true); // if trailing stop is turned off
   }
   
   datetime tm[1];
   tm[0] = 0;
   
   //--- Get the time of last bar in per bar mode
   if (!m_eachtick) {
      //--- If unable to copy time, finish method, repeat on next tick
      if (CopyTime(m_symbol, m_timeframe, 0, 1, tm) == -1) {
         return(false);
      }
      //--- If the bar time is equal to time of method's last execution - finnish method
      if (tm[0] == m_lasttime) {
         return(true);
      }
   }
   
   //--- Get indicator values
   if (!this.refresh()) {
      return(false);
   }
   
   double stoploss;
   ZeroMemory(tradeRequest);
   ZeroMemory(tradeResult);
   
   //--- Obtém o tamanho do tick
   double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   
   //-- Depending on trend, shown by indicator, do various actions
   switch(this.trend()) {
      //--- Up trend
      case 1:
         //--- Select position. If succeeded, then position exists
         //if (PositionSelect(m_symbol)) {
         if (PositionSelectByTicket(ticket)) {
            //--- If position is buy
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
               // Get Stop Loss value for the buy position
               stoploss = this.buyStopLoss();
               
               //--- Find out allowed level of Stop Loss placement for the buy position
               double minimal = SymbolInfoDouble(m_symbol, SYMBOL_BID) - m_point * SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
               
               //--- Value normalizing
               stoploss = NormalizeDouble(stoploss, m_digits);
               minimal = NormalizeDouble(minimal, m_digits);
               
               if (mercadoAOperar == SYMBOL_CALC_MODE_EXCH_STOCKS || mercadoAOperar == SYMBOL_CALC_MODE_EXCH_FUTURES) {
                  // Diminui o resto da divisão do preço com o tick size para igualar ao
                  // último múltiplo do valor de tick size
                  if (fmod(stoploss, tickSize) != 0) {
                     stoploss = stoploss - fmod(stoploss, tickSize);
                  }
               }
               
               //--- If unable to place Stop Loss on level, obtained from indicator,
               // this Stop Loss will be placed on closest possible level
               stoploss = MathMin(stoploss, minimal);
               
               //--- Value of Stop Loss position
               double positionStopLoss = PositionGetDouble(POSITION_SL);
               
               //--- Value normalizing
               positionStopLoss = NormalizeDouble(positionStopLoss, m_digits);
               
               //--- If new value of Stop Loss is bigger than current value of Stop Loss,
               // an attempt to move Stop Loss on a new level will be made
               if (stoploss > positionStopLoss) {
               
                  //--- Determina a quantidade de pontos a adicionar no take profit
                  double tp_pontosAAdicionar = 0;
                  if (positionStopLoss > 0) {
                     tp_pontosAAdicionar = stoploss - positionStopLoss;
                  }
               
                  //--- Filling request struct
                  tradeRequest.action = TRADE_ACTION_SLTP;
                  tradeRequest.position = ticket;
                  tradeRequest.symbol = this.m_symbol;
                  tradeRequest.magic = m_magic;
                  tradeRequest.sl = stoploss;                  
                  tradeRequest.tp = PositionGetDouble(POSITION_TP) == 0 
                  ? PositionGetDouble(POSITION_TP) 
                  : PositionGetDouble(POSITION_TP) + tp_pontosAAdicionar;
                  tradeRequest.comment = "SL " + DoubleToString(stoploss, m_digits) + " / TP " + DoubleToString(tradeRequest.tp, m_digits);
                  
                  //--- Send order
                  bool result = OrderSend(tradeRequest, tradeResult);
                  
                  //--- Check request result
                  if (tradeResult.retcode != TRADE_RETCODE_DONE) {
                     // Log error message
                     Print("Unable to move Stop Loss of ticket ", ticket, ", error: ", GetLastError());
                     //--- Unable to move Stop Loss, finishing
                     return(false);
                  }
               }
            }
         }
         break;
      //--- Down trend
      case -1:
         //--- Select position. If succeeded, then position exists
         //if (PositionSelect(m_symbol)) {
         if (PositionSelectByTicket(ticket)) {
         
            //--- If position is sell
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            
               // Get Stop Loss value for the sell position
               stoploss = this.sellStopLoss();
               
               //--- Adding spread, since Sell is closing by the Ask price
               stoploss += (SymbolInfoDouble(m_symbol, SYMBOL_ASK) - SymbolInfoDouble(m_symbol, SYMBOL_BID));
               
               //--- Find out allowed level of Stop Loss placement for the sell position
               double minimal = SymbolInfoDouble(m_symbol, SYMBOL_ASK) + m_point * SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
               
               //--- Value normalizing
               stoploss = NormalizeDouble(stoploss, m_digits);
               minimal = NormalizeDouble(minimal, m_digits);
               
               if (mercadoAOperar == SYMBOL_CALC_MODE_EXCH_STOCKS || mercadoAOperar == SYMBOL_CALC_MODE_EXCH_FUTURES) {
                  // Diminui o resto da divisão do preço com o tick size para igualar ao
                  // último múltiplo do valor de tick size
                  if (fmod(stoploss, tickSize) != 0) {
                     stoploss = stoploss - fmod(stoploss, tickSize);
                  }
               }
               
               //--- If unable to place Stop Loss on level, obtained from indicator,
               // this Stop Loss will be placed on closest possible level
               stoploss = MathMax(stoploss, minimal);
               
               //--- Value of Stop Loss position
               double positionStopLoss = PositionGetDouble(POSITION_SL);
               
               //--- Value normalizing
               positionStopLoss = NormalizeDouble(positionStopLoss, m_digits);
               
               //--- If new value of Stop Loss is lower than current value of Stop Loss,
               // an attempt to move Stop Loss on a new level will be made
               if (stoploss < positionStopLoss || positionStopLoss == 0) {
               
                  //--- Determina a quantidade de pontos a adicionar no take profit
                  double tp_pontosAAdicionar = 0;
                  if (positionStopLoss > 0) {
                     tp_pontosAAdicionar = stoploss - positionStopLoss;
                  }
               
                  //--- Filling request struct
                  tradeRequest.action = TRADE_ACTION_SLTP;
                  tradeRequest.position = ticket;
                  tradeRequest.symbol = this.m_symbol;
                  tradeRequest.magic = m_magic;
                  tradeRequest.sl = stoploss;
                  tradeRequest.tp = PositionGetDouble(POSITION_TP) == 0 
                     ? PositionGetDouble(POSITION_TP) 
                     : PositionGetDouble(POSITION_TP) - MathAbs(tp_pontosAAdicionar);
                  tradeRequest.comment = "SL " + DoubleToString(stoploss, m_digits) + " / TP " + DoubleToString(tradeRequest.tp, m_digits);
                  
                  //--- Send order
                  bool result = OrderSend(tradeRequest, tradeResult);
                  
                  //--- Check request result
                  if (tradeResult.retcode != TRADE_RETCODE_DONE) {
                     // Log error message
                     Print("Unable to move Stop Loss of ticket ", ticket, ", error: ", GetLastError());
                     //--- Unable to move Stop Loss, finishing
                     return(false);
                  }
               }
            }
         }
         break;
   }
 
   //--- Remember the time of method's last execution
   m_lasttime = tm[0];
   return(true);  
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| CNRTRStop class                                                  |
//+------------------------------------------------------------------+
class CNRTRStop : public CTrailingStop {
  protected:
      double support[1]; // value of support level
      double resistance[1]; // value of resistance level
      
  public:
      void CNRTRStop(void);
      virtual bool setupParameters(int period, double k);
      virtual bool refresh(void);
      virtual int trend(void);
      
      // Method of finding out Stop Loss level for buy
      virtual double buyStopLoss() {
         return(support[0]);
      }
      
      // Method of finding out Stop Loss level for sell
      virtual double sellStopLoss() {
         return(resistance[0]);
      }
};

void CNRTRStop::CNRTRStop(void) {
   this.m_typename = "NRTR"; // value of resistance level
}

//--- Method of setting parameters and loading the indicator
bool CNRTRStop::setupParameters(int period,double k) {
   this.m_handle = iCustom(this.m_symbol, this.m_timeframe, "Downloads\\NRTR", period, k); // loading indicator
   if (this.m_handle == -1) {
      // if unable to load indicator, method returns false
      return(false);
   }
   if (this.m_indicator) {
      ChartIndicatorAdd(0, 0, this.m_handle); // attach indicator to chart
   }
   
   return(true);
}

//--- Method of getting indicator values
bool CNRTRStop::refresh(void) {
   
   // if unable to copy value to array, return false
   if (CopyBuffer(this.m_handle, 0, this.m_shift, 1, support) == -1) {
      return(false);
   }
   
   // if unable to copy value to array, return false
   if (CopyBuffer(this.m_handle, 1, this.m_shift, 1, resistance) == -1) {
      return(false);
   }
   
   return(true);
}

//-- Method of finding trend
int CNRTRStop::trend(void) {
   // there is support line, then it is up trend
   if (support[0] != 0) {
      return(1);
   }
   
   // there is resistance line, then it is down trend
   if (resistance[0] != 0) {
      return(-1);
   }
   
   return(0);
}
//+------------------------------------------------------------------+