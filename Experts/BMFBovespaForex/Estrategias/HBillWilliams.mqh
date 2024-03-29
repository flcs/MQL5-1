//+------------------------------------------------------------------+
//|                                                HBillWilliams.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Arquivo MQH que contém as estratégias para negociação utilizando indicadores Bill Williams."

//--- Inclusão de arquivos
#include "..\\HStrategy.mqh"

//+------------------------------------------------------------------+
//| Classe CAlligator - Sinais de negociação baseado no indicador    |
//| Alligator.                                                       |
//+------------------------------------------------------------------+
class CAlligator : public CStrategy {

   private:
      int alligatorHandle;
      
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

int CAlligator::init(void) {

   //--- Inicializa o indicador Alligator
   this.alligatorHandle = iAlligator(_Symbol, _Period, 13, 0, 8, 0, 5, 0, MODE_SMMA, PRICE_MEDIAN);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.alligatorHandle < 0) {
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CAlligator::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.alligatorHandle);
}

int CAlligator::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   //-- Armaze os valores do indicador Alligator
   double alligatorBuffer1[], alligatorBuffer2[], alligatorBuffer3[];
   
   //--- Copia os valores dos indicadores para seus respectivos buffers
   if (CopyBuffer(this.alligatorHandle, 0, 0, 2, alligatorBuffer1) < 2
      || CopyBuffer(this.alligatorHandle, 1, 0, 2, alligatorBuffer2) < 2
      || CopyBuffer(this.alligatorHandle, 2, 0, 2, alligatorBuffer3) < 2) {
      Print("Falha ao copiar os dados dos indicadores para os buffers! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(alligatorBuffer1, true) || !ArraySetAsSeries(alligatorBuffer2, true)
      || !ArraySetAsSeries(alligatorBuffer3, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica os dados do indicador para determinar os sinais de negociação
   if (alligatorBuffer3[1] > alligatorBuffer2[1] && alligatorBuffer2[1] > alligatorBuffer1[1]) {
      sinal = 1;
   } else if (alligatorBuffer3[1] < alligatorBuffer2[1] && alligatorBuffer2[1] < alligatorBuffer1[1]) {
      sinal = -1;
   } else {
      sinal = 0;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CAlligator::sinalConfirmacao(int sinalNegociacao) {
   
   //--- O sinal é passado direto, uma vez que todas as condições de entrada na 
   //--- negociação foram previamente atendidas.
   int sinal = sinalNegociacao;
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CAlligator::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CSinalWPR - Sinais de negociação baseado no oscilador     |
//| William's Percent Range (%)                                      |
//+------------------------------------------------------------------+
class CSinalWPR : public CStrategy {

   private:
      int wprHandle;

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

int CSinalWPR::init(void) {

   this.wprHandle = iWPR(_Symbol, _Period, 14);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.wprHandle < 0) {
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CSinalWPR::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.wprHandle);
}

int CSinalWPR::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double wprBuffer[]; // Armazena os valores do oscilador William's Percent Range
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.wprHandle, 0, 0, 3, wprBuffer) < 3) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(wprBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica os valores do indicador e seta o sinal de negociação
   if (wprBuffer[2] < -80 && wprBuffer[1] > -80) {
      sinal = 1;
   } else if (wprBuffer[2] > -20 && wprBuffer[1] < -20) {
      sinal = -1;
   } else {
      sinal = 0;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CSinalWPR::sinalConfirmacao(int sinalNegociacao) {
   
   int sinal = sinalNegociacao;
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CSinalWPR::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CAwesome - Sinais de negociação baseado no oscilador      |
//| Maravilhoso (Awesome Oscillator).                                |
//+------------------------------------------------------------------+
class CAwesome : public CStrategy {

   private:
      int aoHandle;

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

int CAwesome::init(void) {

   this.aoHandle = iAO(_Symbol, _Period);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.aoHandle < 0) {
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CAwesome::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.aoHandle);
}

int CAwesome::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double aoBuffer[]; // Armazena os valores do oscilador Awesome
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.aoHandle, 1, 0, 20, aoBuffer) < 20) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(aoBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica os valores do indicador e seta o sinal de negociação
   if (aoBuffer[1] == 0) {
      sinal = 1;
   } else if (aoBuffer[1] == 1) {
      sinal = -1;
   } else {
      sinal = 0;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CAwesome::sinalConfirmacao(int sinalNegociacao) {
   
   int sinal = sinalNegociacao;
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CAwesome::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

//+------------------------------------------------------------------+

/* Desde ponto em diante ficam as declarações das classes das estratégias
   declaradas neste arquivo MQH
*/

//--- Declaração de classes
CSinalWPR cSinalWPR;
CAwesome cAwesome;
CAlligator cAlligator;

//+------------------------------------------------------------------+