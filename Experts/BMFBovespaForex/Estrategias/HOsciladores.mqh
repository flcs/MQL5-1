//+------------------------------------------------------------------+
//|                                                 HOsciladores.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Arquivo MQH que contém as estratégias para negociação utilizando osciladores."

//--- Inclusão de arquivos
#include "..\\HStrategy.mqh"

//+------------------------------------------------------------------+
//| Classe CSinalATR - Sinais de negociação baseado no oscilador ATR |
//| que gera sinais de negociação segundo a direção do candle. O     |
//| o corpo do candle deve ter um valor maior que o valor k.         |
//+------------------------------------------------------------------+
class CSinalATR : public CStrategy {

   private:
      int atrHandle;

   public:
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

int CSinalATR::init(void) {

   this.atrHandle = iATR(_Symbol, _Period, 20); // Período ATR: 20
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.atrHandle < 0) {
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CSinalATR::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.atrHandle);
}

int CSinalATR::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double atrBuffer[]; // Armazena o valor do oscilador ATR
   
   //--- Copia o valor do indicador para seu respectivo buffer
   //--- É obtido o valor ATR da penúltima barra concluída (o índice da barra é igual a 2)
   if (CopyBuffer(this.atrHandle, 0, 2, 1, atrBuffer) < 1) {
      Print("Falha ao copiar os dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Copia os dados da última barra fechada numa matriz do tipo MqlRates
   MqlRates ultimaBarra[1];
   if (CopyRates(_Symbol, _Period, 1, 1, ultimaBarra) < 1) {
      Print("Falha ao copiar os dados da última barra para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(atrBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Calculamos o tamanho do corpo da última barra fechada
   double corpoUltimaBarra = ultimaBarra[0].close - ultimaBarra[0].open;
   
   // Se o corpo da última barra (com índice 1) exceder o valor anterior do ATR
   // (na barra com índice 2), um sinal de negociação é recebido.
   if (MathAbs(corpoUltimaBarra) > 3 * atrBuffer[0]) { // valor do k = 3
      sinal = corpoUltimaBarra > 0 ? 1 : -1;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CSinalATR::sinalConfirmacao(int sinalNegociacao) {
   
   int sinal = sinalNegociacao;
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CSinalATR::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CSinalCCI - Sinais de negociação baseado no oscilador CCI.|
//+------------------------------------------------------------------+
class CSinalCCI : public CStrategy {

   private:
      int cciHandle;

   public:
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

int CSinalCCI::init(void) {

   this.cciHandle = iCCI(_Symbol, _Period, 14, PRICE_TYPICAL);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.cciHandle < 0) {
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CSinalCCI::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.cciHandle);
}

int CSinalCCI::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double cciBuffer[]; // Armazena os valores do oscilador CCI
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.cciHandle, 0, 0, 3, cciBuffer) < 3) {
      Print("Falha ao copiar os dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(cciBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica os valores do indicador e seta o sinal de negociação
   if (cciBuffer[2] < -100 && cciBuffer[1] > -100 ) {
      sinal = 1;
   } else if (cciBuffer[2] > 100 && cciBuffer[1] < 100) {
      sinal = -1;
   } else {
      sinal = 0;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CSinalCCI::sinalConfirmacao(int sinalNegociacao) {
   
   int sinal = sinalNegociacao;
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CSinalCCI::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CSinalMACD - Sinais de negociação baseado no oscilador    |
//| MACD                                                             |
//+------------------------------------------------------------------+
class CSinalMACD : public CStrategy {

   private:
      int macdHandle;

   public:
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

int CSinalMACD::init(void) {

   this.macdHandle = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.macdHandle < 0) {
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CSinalMACD::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.macdHandle);
}

int CSinalMACD::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double macdBuffer[], signalBuffer[]; // Armazena os valores do oscilador MACD
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.macdHandle, 0, 0, 2, macdBuffer) < 2
      || CopyBuffer(this.macdHandle, 1, 0, 3, signalBuffer) < 3) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(macdBuffer, true) || !ArraySetAsSeries(signalBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- perform checking of the condition and set the value for sig
   if (signalBuffer[2] > macdBuffer[1] && signalBuffer[1] < macdBuffer[1]) {
      sinal = 1;
   } else if (signalBuffer[2] < macdBuffer[1] && signalBuffer[1] > macdBuffer[1]) {
      sinal = -1;
   } else {
      sinal = 0;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CSinalMACD::sinalConfirmacao(int sinalNegociacao) {
   
   int sinal = sinalNegociacao;
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CSinalMACD::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CSinalRSI - Sinais de negociação baseado no oscilador RSI.|
//+------------------------------------------------------------------+
class CSinalRSI : public CStrategy {

   private:
      int rsiHandle;

   public:
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

int CSinalRSI::init(void) {

   this.rsiHandle = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.rsiHandle < 0) {
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CSinalRSI::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.rsiHandle);
}

int CSinalRSI::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double rsiBuffer[]; // Armazena os valores do oscilador RSI
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.rsiHandle, 0, 0, 3, rsiBuffer) < 3) {
      Print("Falha ao copiar os dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(rsiBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica os valores do indicador e seta o sinal de negociação
   if (rsiBuffer[2] < 30 && rsiBuffer[1] > 30) {
      sinal = 1;
   } else if (rsiBuffer[2] > 70 && rsiBuffer[1] < 70) {
      sinal = -1;
   } else {
      sinal = 0;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CSinalRSI::sinalConfirmacao(int sinalNegociacao) {
   
   int sinal = sinalNegociacao;
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CSinalRSI::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CSinalEstocastico - Sinais de negociação baseado no       |
//| oscilador Estocástico                                            |
//+------------------------------------------------------------------+
class CSinalEstocastico : public CStrategy {

   private:
      int estocasticoHandle;

   public:
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

int CSinalEstocastico::init(void) {

   estocasticoHandle = iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (estocasticoHandle < 0) {
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CSinalEstocastico::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(estocasticoHandle);
}

int CSinalEstocastico::sinalNegociacao(void) {

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

int CSinalEstocastico::sinalConfirmacao(int sinalNegociacao) {
   
   int sinal = sinalNegociacao;
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CSinalEstocastico::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

//+------------------------------------------------------------------+

/* Desde ponto em diante ficam as declarações das classes das estratégias
   declaradas neste arquivo MQH
*/

//--- Declaração de classes
CSinalMACD cSinalMACD;
CSinalEstocastico cSinalEstocastico;
CSinalATR cSinalATR;
CSinalRSI cSinalRSI;
CSinalCCI cSinalCCI;

//+------------------------------------------------------------------+