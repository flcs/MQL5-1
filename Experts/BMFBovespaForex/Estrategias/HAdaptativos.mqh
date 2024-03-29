//+------------------------------------------------------------------+
//|                                                 HAdaptativos.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Arquivo MQH que contém as estratégias para negociação utilizando indicadores adaptativos em geral."

//--- Inclusão de arquivos
#include "..\\HStrategy.mqh"

//+------------------------------------------------------------------+
//| Classe CSinalAMA - Sinais de negociação baseado no Adaptive      |
//| Moving Average (AMA)                                             |
//+------------------------------------------------------------------+
class CSinalAMA : public CStrategy {

   private:
      int amaHandle;

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

int CSinalAMA::init(void) {

   this.amaHandle = iAMA(_Symbol, _Period, 9, 2, 30, 0, PRICE_CLOSE);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.amaHandle < 0) {
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CSinalAMA::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.amaHandle);
}

int CSinalAMA::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double amaBuffer[]; // Armazena os valores do indicador AMA
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.amaHandle, 0, 0, 3, amaBuffer) < 3) {
      Print("Falha ao copiar os dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(amaBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica os dados do indicador para determinar o sinal de negociação
   if (amaBuffer[2] < amaBuffer[1]) {
      sinal = 1;
   } else if (amaBuffer[2] > amaBuffer[1]) {
      sinal = -1;
   } else {
      sinal = 0;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CSinalAMA::sinalConfirmacao(int sinalNegociacao) {
   
   int sinal = sinalNegociacao;
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CSinalAMA::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CAdaptiveChannelADX - Sinais de negociação baseado no     |
//| indicador customizado Adaptive Channel ADX.                      |
//+------------------------------------------------------------------+
class CAdaptiveChannelADX : public CStrategy {

   private:
      int customHandle;

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

int CAdaptiveChannelADX::init(void) {

   this.customHandle = iCustom(_Symbol, _Period, "Artigos\\AdaptiveChannelADX", 14);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.customHandle < 0) {
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CAdaptiveChannelADX::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.customHandle);
}

int CAdaptiveChannelADX::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   //--- Armazena os valores do indicador e o close das últimas barras
   double adxBuffer1[], adxBuffer2[], close[];
   
   //--- Copia os valores dos indicadores para seus respectivos buffers
   if (CopyBuffer(this.customHandle, 0, 0, 2, adxBuffer1) < 2
      || CopyBuffer(this.customHandle, 1, 0, 2, adxBuffer2) < 2
      || CopyClose(_Symbol, _Period, 0, 2, close) < 2) {
      Print("Falha ao copiar os dados dos indicadores para os buffers! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(adxBuffer1, true) || !ArraySetAsSeries(adxBuffer2, true)
      || !ArraySetAsSeries(close, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica os dados do indicador para determinar o sinal de negociação
   if (close[1] > adxBuffer1[1]) {
      sinal = 1;
   } else if (close[1] < adxBuffer2[1]) {
      sinal = -1;
   } else {
      sinal = 0;
   }
      
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CAdaptiveChannelADX::sinalConfirmacao(int sinalNegociacao) {
   
   int sinal = sinalNegociacao;
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CAdaptiveChannelADX::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

//+------------------------------------------------------------------+

/* Desde ponto em diante ficam as declarações das classes das estratégias
   declaradas neste arquivo MQH
*/

//--- Declaração de classes
CSinalAMA cSinalAMA;
CAdaptiveChannelADX cAdaptiveChannelADX;

//+------------------------------------------------------------------+