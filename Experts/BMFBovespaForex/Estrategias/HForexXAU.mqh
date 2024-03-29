//+------------------------------------------------------------------+
//|                                                    HForexXAU.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Arquivo MQH que contém as estratégias para negociação no mercado Forex com ouro (XAU)."

//--- Inclusão de arquivos
#include "..\\HStrategy.mqh"

//+------------------------------------------------------------------+
//| Classe CForexXAUEUR - Sinais de negociação baseado no indicador  |
//| ADX 8 períodos e com confirmação de tendência a partir de uma MA |
//| exponencial de 8 períodos. O usuário é notificado dos lucros e/ou|
//| prejuízos a cada 5 minutos. Esta estratégia é para o ativo       |
//| XAUEUR no gráfico de 4 horas (H4).                                |
//+------------------------------------------------------------------+
class CForexXAUEUR : public CStrategy {

   private:
      int adxHandle;
      int maHandle;
      int contNotificarUsuario;

   public:
      //--- Métodos
      virtual int init(void);
      virtual void release(void);
      virtual int sinalNegociacao(void);
      virtual int sinalConfirmacao(int sinalNegociacao);
      virtual int sinalSaidaNegociacao(int chamadaSaida);
      virtual void notificarUsuario(int sinalChamada);  
      
      int onTickBarTimer(void) {
         return(1); // Nova barra
      }    

};

int CForexXAUEUR::init(void) {

   //--- Inicializa o indicador ADX
   this.adxHandle = iADX(_Symbol, 0, 8); // Período ADX = 8
   
   //--- Inicializa o indicador MA
   this.maHandle = iMA(_Symbol, _Period, 8, 0, MODE_EMA, PRICE_CLOSE); // Período MA exponencial = 8

   //--- Verifica se os indicadores foram criados com sucesso
   if (this.adxHandle < 0 || this.maHandle < 0) {
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CForexXAUEUR::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.adxHandle);
   IndicatorRelease(this.maHandle);
}

int CForexXAUEUR::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   //--- Armazena os valores dos indicadores ADX e MA
   double plusDI[], minusDI[], adxValue[], maValue[];
   
   //--- Armazena as informações de cada barra
   MqlRates tradeRate[];
   
   //--- Copia os valores dos indicadores para seus respectivos buffers
   if (CopyBuffer(this.adxHandle, 0, 0, 3, adxValue) < 0
      || CopyBuffer(this.adxHandle, 1, 0, 3, plusDI) < 0
      || CopyBuffer(this.adxHandle, 2, 0, 3, minusDI) < 0
      || CopyBuffer(this.maHandle, 0, 0, 3, maValue) < 0
      || CopyRates(_Symbol, _Period, 0, 3, tradeRate) < 0) {
      Print("Falha ao copiar os dados dos indicadores para os buffers! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(adxValue, true) || !ArraySetAsSeries(maValue, true)
      || !ArraySetAsSeries(plusDI, true) || !ArraySetAsSeries(minusDI, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- A partir dos valores obtidos dos indicadores, determina se temos um sinal de compra
   bool buyCondition1 = (maValue[0] > maValue[1]) && (maValue[1] > maValue[2]); // MA-8 Increasing upwards
   bool buyCondition2 = (tradeRate[1].close > maValue[1]); // previous price closed above MA-8
   bool buyCondition3 = (adxValue[0] > 22); // Current ADX value greater than minimun value (22)
   bool buyCondition4 = (plusDI[0] > minusDI[0]); // +DI greater than -DI
   
   //--- Put all together
   if (buyCondition1 && buyCondition2) {
      if (buyCondition3 && buyCondition4) {
         //-- Sinal de compra
         //sinal = 1;
         
         //--- O sinal foi invertido porque o ADX indica mais pontos de reversão do que de
         //--- negociação a favor da tendência
         sinal = -1;
      }
   }
   
   //--- A partir dos valores obtidos dos indicadores, determina se termos um sinal de venda
   bool sellCondition1 = (maValue[0] < maValue[1]) && (maValue[1] < maValue[2]); // MA-8 Decreasing downwards
   bool sellCondition2 = (tradeRate[1].close < maValue[1]); // previous price closed below MA-8
   bool sellCondition3 = (adxValue[0] > 22); // Current ADX value greater than minimun value (22)
   bool sellCondition4 = (plusDI[0] < minusDI[0]); // -DI greater than +DI
   
   //--- Put all together
   if (sellCondition1 && sellCondition2) {
      if (sellCondition3 && sellCondition4) {
         //sinal = -1;
         
         //--- O sinal foi invertido porque o ADX indica mais pontos de reversão do que de
         //--- negociação a favor da tendência
         sinal = 1;
      }
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CForexXAUEUR::sinalConfirmacao(int sinalNegociacao) {
   
   //--- O sinal é passado direto, uma vez que todas as condições de entrada na 
   //--- negociação foram previamente atendidas.
   int sinal = sinalNegociacao;
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CForexXAUEUR::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

void CForexXAUEUR::notificarUsuario(int sinalChamada) {
   
   //--- Notifica a cada 5 minutos dos ganhos e perdas financeiras
   if (sinalChamada == 9 && this.contNotificarUsuario == 5) {
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            double lucro = PositionGetDouble(POSITION_PROFIT);
            if (lucro <= -50) {
               //--- Envia uma mensage ao usuário informando do prejuízo               
               cUtil.enviarMensagemUsuario("Prejuízo de " 
               + AccountInfoString(ACCOUNT_CURRENCY) 
               + DoubleToString(PositionGetDouble(POSITION_PROFIT)) 
               + " gerado pelo ticket #" 
               + IntegerToString(PositionGetTicket(i)) + " no símbolo " + _Symbol + "...");
            } else if (lucro >= 50) {
               //--- Envia uma mensage ao usuário informando do lucro
               cUtil.enviarMensagemUsuario("Lucro de " 
               + AccountInfoString(ACCOUNT_CURRENCY) 
               + DoubleToString(PositionGetDouble(POSITION_PROFIT)) 
               + " gerado pelo ticket #" 
               + IntegerToString(PositionGetTicket(i)) + " no símbolo " + _Symbol + "...");
            }
            this.contNotificarUsuario = 0;
            break;
         }
      }
   } else if (sinalChamada == 9) {  
      this.contNotificarUsuario++;
   }
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CForexXAUUSD - Sinais de negociação baseado no oscilador  |
//| MACD usando as opções padrão, com notificação para o usuário de  |
//| lucro e/ou prejuízo das posições abertas. Este estratégia é para |
//| operar com o ativo XAUUSD no gráfico de 30 minutos (M30).        |
//+------------------------------------------------------------------+
class CForexXAUUSD : public CStrategy {

   private:
      int macdHandle;
      int maHandle;
      int contNotificarUsuario;

   public:
      //--- Métodos
      virtual int init(void);
      virtual void release(void);
      virtual int sinalNegociacao(void);
      virtual int sinalConfirmacao(int sinalNegociacao);
      virtual int sinalSaidaNegociacao(int chamadaSaida);
      virtual void notificarUsuario(int sinalChamada); 
      
      int onTickBarTimer(void) {
         return(1); // Nova barra
      }    

};

int CForexXAUUSD::init(void) {

   this.macdHandle = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
   this.maHandle = iMA(_Symbol, _Period, 26, 0, MODE_EMA, PRICE_CLOSE);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.macdHandle < 0 || this.maHandle < 0) {
      Alert("Erro ao criar os indicadores! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CForexXAUUSD::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.macdHandle);
   IndicatorRelease(this.maHandle);
}

int CForexXAUUSD::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double maBuffer[], macdBuffer[], signalBuffer[]; // Armazena os valores do oscilador MACD e da MA exponencial
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.macdHandle, 0, 0, 2, macdBuffer) < 2
      || CopyBuffer(this.macdHandle, 1, 0, 2, signalBuffer) < 2
      || CopyBuffer(this.maHandle, 0, 0, 2, maBuffer) < 2) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
 
   //--- Popula as variáveis auxiliares
   double macdCurrent = macdBuffer[0];
   double macdPrevious = macdBuffer[1];
   double signalCurrent = signalBuffer[0];
   double signalPrevious = signalBuffer[1];
   double maCurrent = maBuffer[0];
   double maPrevious = maBuffer[1];
   
   //--- Verifica os dados obtidos dos indicadores para determinar o sinal de negociação
   
   //--- Posição longa (COMPRA)
   if (macdCurrent < 0) {
      if (macdCurrent > signalCurrent && macdPrevious < signalPrevious) {
         if (maCurrent > maPrevious) {
            sinal = 1;
         }
      }
   }
   
   //--- Posição curta (VENDA)
   if (macdCurrent > 0) {
      if (macdCurrent < signalCurrent && macdPrevious > signalPrevious) {
         if (maCurrent < maPrevious) {
            sinal = -1;
         }
      }
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CForexXAUUSD::sinalConfirmacao(int sinalNegociacao) {
   
   int sinal = sinalNegociacao;
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CForexXAUUSD::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

void CForexXAUUSD::notificarUsuario(int sinalChamada) {
   
   //--- Notifica a cada 5 minutos dos ganhos e perdas financeiras
   if (sinalChamada == 9 && this.contNotificarUsuario == 5) {
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            double lucro = PositionGetDouble(POSITION_PROFIT);
            if (lucro <= -35) {
               //--- Envia uma mensage ao usuário informando do prejuízo               
               cUtil.enviarMensagemUsuario("Prejuízo de " 
               + AccountInfoString(ACCOUNT_CURRENCY) 
               + DoubleToString(PositionGetDouble(POSITION_PROFIT)) 
               + " gerado pelo ticket #" 
               + IntegerToString(PositionGetTicket(i)) + " no símbolo " + _Symbol + "...");
            } else if (lucro >= 35) {
               //--- Envia uma mensage ao usuário informando do lucro
               cUtil.enviarMensagemUsuario("Lucro de " 
               + AccountInfoString(ACCOUNT_CURRENCY) 
               + DoubleToString(PositionGetDouble(POSITION_PROFIT)) 
               + " gerado pelo ticket #" 
               + IntegerToString(PositionGetTicket(i)) + " no símbolo " + _Symbol + "...");
            }
            this.contNotificarUsuario = 0;
            break;
         }
      }
   } else if (sinalChamada == 9) {  
      this.contNotificarUsuario++;
   }
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CForexXAUAUD - Sinais de negociação baseado no oscilador  |
//| Estocástico nas configurações padrão, e com notificação para o   |
//| usuário de lucro/prejuízo a cada 5 minutos. Esta estratégia foi  |
//| implementada para operar o ativo XAUAUD no gráfico de 1 hora     |
//| (H1).                                                            |
//+------------------------------------------------------------------+
class CForexXAUAUD : public CStrategy {

   private:
      int estocasticoHandle;
      int contNotificarUsuario;

   public:
      //--- Métodos
      virtual int init(void);
      virtual void release(void);
      virtual int sinalNegociacao(void);
      virtual int sinalConfirmacao(int sinalNegociacao);
      virtual int sinalSaidaNegociacao(int chamadaSaida);
      virtual void notificarUsuario(int sinalChamada); 
      
      int onTickBarTimer(void) {
         return(1); // Nova barra
      }    

};

int CForexXAUAUD::init(void) {

   estocasticoHandle = iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (estocasticoHandle < 0) {
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CForexXAUAUD::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(estocasticoHandle);
}

int CForexXAUAUD::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double estocasticoBuffer[]; // Armazena os valores do oscilador estocástico
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(estocasticoHandle, 0, 0, 3, estocasticoBuffer) < 3) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(estocasticoBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- perform checking of the condition and set the value for sig
   if (estocasticoBuffer[2] < 20 && estocasticoBuffer[1] > 20) {
      sinal = 1;
   } else if (estocasticoBuffer[2] > 80 && estocasticoBuffer[1] < 80) {
      sinal = -1;
   } else {
      sinal = 0;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CForexXAUAUD::sinalConfirmacao(int sinalNegociacao) {
   
   int sinal = sinalNegociacao;
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CForexXAUAUD::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

void CForexXAUAUD::notificarUsuario(int sinalChamada) {
   
   //--- Notifica a cada 5 minutos dos ganhos e perdas financeiras
   if (sinalChamada == 9 && this.contNotificarUsuario == 5) {
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            double lucro = PositionGetDouble(POSITION_PROFIT);
            if (lucro <= -35) {
               //--- Envia uma mensage ao usuário informando do prejuízo               
               cUtil.enviarMensagemUsuario("Prejuízo de " 
               + AccountInfoString(ACCOUNT_CURRENCY) 
               + DoubleToString(PositionGetDouble(POSITION_PROFIT)) 
               + " gerado pelo ticket #" 
               + IntegerToString(PositionGetTicket(i)) + " no símbolo " + _Symbol + "...");
            } else if (lucro >= 35) {
               //--- Envia uma mensage ao usuário informando do lucro
               cUtil.enviarMensagemUsuario("Lucro de " 
               + AccountInfoString(ACCOUNT_CURRENCY) 
               + DoubleToString(PositionGetDouble(POSITION_PROFIT)) 
               + " gerado pelo ticket #" 
               + IntegerToString(PositionGetTicket(i)) + " no símbolo " + _Symbol + "...");
            }
            this.contNotificarUsuario = 0;
            break;
         }
      }
   } else if (sinalChamada == 9) {  
      this.contNotificarUsuario++;
   }
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

/* Desde ponto em diante ficam as declarações das classes das estratégias
   declaradas neste arquivo MQH
*/

//--- Declaração de classes
CForexXAUEUR cForexXAUEUR;
CForexXAUUSD cForexXAUUSD;
CForexXAUAUD cForexXAUAUD;

//+------------------------------------------------------------------+