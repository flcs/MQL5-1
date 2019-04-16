//+------------------------------------------------------------------+
//|                                       ArtificialIntelligence.mq5 |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property version   "1.3"
#property description "Versão modificada e atualizada do EA ArtificialIntelligence desenvolvido originalmente por Yury V. Reshetov ICQ:282715499  http://reshetov.xnet.uz/."
#property description "Artigo: Como desenvolver uma estratégia de negociação lucrativa."
#property description "Link: https://www.mql5.com/pt/articles/1447"
#property description "Versão original do EA disponível em https://www.mql5.com/en/code/10281. As adaptações de MQL4 para MQL5 foram baseadas no artigo https://www.mql5.com/pt/articles/81."

//---- Constantes MQL4
#define SELECT_BY_POS 0
#define MODE_TRADES 0

//---- input parameters
input int x1 = 120; // Variável x1
input int x2 = 172; // Variável x2
input int x3 = 39; // Variável x3
input int x4 = 172; // Variável x4

// StopLoss level
input double sl = 50; // Stop loss
input double lots = 0.1; // Lots
input int    MagicNumber = 888; // Número mágico EA

static datetime prevtime = 0;
static int spread = 3;

//-- Conversão dos timeframes do MQL4 para o MQL5
ENUM_TIMEFRAMES TFMigrate(int tf)
  {
   switch(tf)
     {
      case 0: return(PERIOD_CURRENT);
      case 1: return(PERIOD_M1);
      case 5: return(PERIOD_M5);
      case 15: return(PERIOD_M15);
      case 30: return(PERIOD_M30);
      case 60: return(PERIOD_H1);
      case 240: return(PERIOD_H4);
      case 1440: return(PERIOD_D1);
      case 10080: return(PERIOD_W1);
      case 43200: return(PERIOD_MN1);
      
      case 2: return(PERIOD_M2);
      case 3: return(PERIOD_M3);
      case 4: return(PERIOD_M4);      
      case 6: return(PERIOD_M6);
      case 10: return(PERIOD_M10);
      case 12: return(PERIOD_M12);
      case 16385: return(PERIOD_H1);
      case 16386: return(PERIOD_H2);
      case 16387: return(PERIOD_H3);
      case 16388: return(PERIOD_H4);
      case 16390: return(PERIOD_H6);
      case 16392: return(PERIOD_H8);
      case 16396: return(PERIOD_H12);
      case 16408: return(PERIOD_D1);
      case 32769: return(PERIOD_W1);
      case 49153: return(PERIOD_MN1);      
      default: return(PERIOD_CURRENT);
     }
  }


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   datetime Time[];
   ArraySetAsSeries(Time, true);
   
   if (CopyTime(_Symbol, _Period, 0, 1, Time) < 0) {
      Alert("Error in copying historical times data, error = ", GetLastError());
      return;
   }
  
   if(Time[0] == prevtime) {
       return;
   }
   prevtime = Time[0];
//----
   if(MQL5InfoInteger(MQL5_TRADE_ALLOWED)) 
     {
       spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
     } 
   else 
     {
       prevtime = Time[1];
       return;
     }
   int ticket = -1;
// check for opened position
   int total = OrdersTotal();   
   for(int i = 0; i < total; i++) 
     {
       OrderSelect(i, SELECT_BY_POS, MODE_TRADES); 
       // check for symbol & magic number
       if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) 
         {
           int prevticket = OrderTicket();
           // long position is opened
           if (OrderType() == OP_BUY) 
             {
               // check profit 
               if(Bid > (OrderStopLoss() + (sl * 2  + spread) * Point)) 
                 {               
                   if(perceptron() < 0) 
                     { 
                       // reverse
                       ticket = OrderSend(Symbol(), OP_SELL, lots * 2, Bid, 3, 
                                          Ask + sl * Point, 0, "AI", MagicNumber, 
                                          0, Red); 
                       Sleep(30000);
                       if(ticket < 0) 
                         {
                           prevtime = Time[1];
                         } 
                       else 
                         {
                           OrderCloseBy(ticket, prevticket, Blue);   
                         }
                     } 
                   else 
                     { 
                       // trailing stop
                       if(!OrderModify(OrderTicket(), OrderOpenPrice(), 
                          Bid - sl * Point, 0, 0, Blue)) 
                         {
                           Sleep(30000);
                           prevtime = Time[1];
                         }
                     }
                 }  
               // short position is opened
             } 
           else 
             {
               // check profit 
               if(Ask < (OrderStopLoss() - (sl * 2 + spread) * Point)) 
                 {
                   if(perceptron() > 0) 
                     { 
                       // reverse
                       ticket = OrderSend(Symbol(), OP_BUY, lots * 2, Ask, 3, 
                                          Bid - sl * Point, 0, "AI", MagicNumber, 
                                          0, Blue); 
                       Sleep(30000);
                       if(ticket < 0) 
                         {
                           prevtime = Time[1];
                         } 
                       else 
                         {
                           OrderCloseBy(ticket, prevticket, Blue);   
                         }
                     } 
                   else 
                     { 
                       // trailing stop
                       if(!OrderModify(OrderTicket(), OrderOpenPrice(), 
                          Ask + sl * Point, 0, 0, Blue)) 
                         {
                           Sleep(30000);
                           prevtime = Time[1];
                         }
                     }
                 }  
             }
           // exit
           return(0);
         }
     }
// check for long or short position possibility
   if(perceptron() > 0) 
     { 
       //long
       ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, 3, Bid - sl * Point, 0, 
                          "AI", MagicNumber, 0, Blue); 
       if(ticket < 0) 
         {
           Sleep(30000);
           prevtime = Time[1];
         }
     } 
   else 
     { 
       // short
       ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, 3, Ask + sl * Point, 0, 
                          "AI", MagicNumber, 0, Red); 
       if(ticket < 0) 
         {
           Sleep(30000);
           prevtime = Time[1];
         }
     }
//--- exit
   return;
  }
//+------------------------------------------------------------------+
//|  The PERCEPRRON - a perceiving and recognizing function          |
//+------------------------------------------------------------------+
double perceptron() 
  {
   double w1 = x1 - 100.0;
   double w2 = x2 - 100.0;
   double w3 = x3 - 100.0;
   double w4 = x4 - 100.0;
   double a1 = iACMQL4(Symbol(), 0, 0);
   double a2 = iACMQL4(Symbol(), 0, 7);
   double a3 = iACMQL4(Symbol(), 0, 14);
   double a4 = iACMQL4(Symbol(), 0, 21);
   return (w1 * a1 + w2 * a2 + w3 * a3 + w4 * a4);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|  Versão em MQL5 do oscilador do aceleração/desaceleração Bill    |
//|  Williams.                                                       |
//+------------------------------------------------------------------+
double iACMQL4(string symbol, int tf, int shift)
  {
   ENUM_TIMEFRAMES timeframe = TFMigrate(tf);
   int handle=iAC(symbol,timeframe);
   if(handle<0)
     {
      Print("The iAC object is not created: Error", GetLastError());
      return(-1);
     }
   else
      return(CopyBufferMQL4(handle,0,shift));
  }
  
//+------------------------------------------------------------------+
//|  Versão adaptada do CopyBuffer do MQL4 para o MQL5               |
//+------------------------------------------------------------------+  
double CopyBufferMQL4(int handle,int index,int shift)
  {
   double buf[];
   switch(index)
     {
      case 0: if(CopyBuffer(handle,0,shift,1,buf)>0)
         return(buf[0]); break;
      case 1: if(CopyBuffer(handle,1,shift,1,buf)>0)
         return(buf[0]); break;
      case 2: if(CopyBuffer(handle,2,shift,1,buf)>0)
         return(buf[0]); break;
      case 3: if(CopyBuffer(handle,3,shift,1,buf)>0)
         return(buf[0]); break;
      case 4: if(CopyBuffer(handle,4,shift,1,buf)>0)
         return(buf[0]); break;
      default: break;
     }
   return(EMPTY_VALUE);
  }