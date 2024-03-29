//+------------------------------------------------------------------+
//|                                                HCustomizados.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Arquivo MQH que contém as estratégias para negociação utilizando indicadores customizados."

//--- Inclusão de arquivos
#include "..\\HStrategy.mqh"

//+------------------------------------------------------------------+
//| Classe CFreelanceJob - Estratégia criada para implementar um     |
//| freelance de exemplo que obtive no site MQL5. Detalhes do job    |
//| estão descritos na tarefa #83.                                   |
//| Basicamente a estratégia gera sinais de negociação baseado nos   |
//| indicadores WMA, RVI, MACD e ATR, e também compara os sinais em  |
//| um timeframe superior para confirmar a tendência.                |
//+------------------------------------------------------------------+
class CFreelanceJob : public CStrategy {

   private:
      int rviHandle;
      int macdHandle;
      int wmaHandle;
      int atrHandle;
      int wmaHighPeriodHandle;

   public:
      //--- Métodos
      virtual int init(void);
      virtual void release(void);
      virtual int sinalNegociacao(void);
      virtual int sinalConfirmacao(int sinalNegociacao);
      virtual int sinalSaidaNegociacao(int chamadaSaida);  
      virtual double obterStopLoss(ENUM_ORDER_TYPE tipoOrdem, double preco);
      virtual double obterTakeProfit(ENUM_ORDER_TYPE tipoOrdem, double preco);        
      
      int onTickBarTimer(void) {
         return(1); // Nova barra
      }    

};

int CFreelanceJob::init(void) {

   //--- RVI(8)
   this.rviHandle = iRVI(_Symbol, _Period, 8);
   
   //--- MACD(12,26,9, Close)
   this.macdHandle = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
   
   //--- ATR(14)
   this.atrHandle = iATR(_Symbol, _Period, 14);
   
   //--- WMA(14, close)
   this.wmaHandle = iCustom(_Symbol, _Period, "Downloads\\WMA", 14, PRICE_CLOSE);
   
   ENUM_TIMEFRAMES periodo = _Period;
   
   //--- Verifica se o período selecionado para determinar qual será o período acima 
   //--- que precisará ser verificado
   switch(periodo) {
      case PERIOD_M5: periodo = PERIOD_M15; break;
      case PERIOD_M15: periodo = PERIOD_H1; break;
   }
   
   //--- WMA(14, close) - timeframe superior ao selecionado
   this.wmaHighPeriodHandle = iCustom(_Symbol, periodo, "Downloads\\WMA", 14, PRICE_CLOSE);

   //--- Verifica se os indicadores foram criados com sucesso
   if (this.rviHandle == INVALID_HANDLE || this.macdHandle == INVALID_HANDLE 
      || this.wmaHandle == INVALID_HANDLE || this.atrHandle == INVALID_HANDLE
      || this.wmaHighPeriodHandle == INVALID_HANDLE) {
      
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(INIT_FAILED);
      
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CFreelanceJob::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.atrHandle);
   IndicatorRelease(this.macdHandle);
   IndicatorRelease(this.rviHandle);
   IndicatorRelease(this.wmaHandle);
   IndicatorRelease(this.wmaHighPeriodHandle);
}

int CFreelanceJob::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   //--- Armazena o buffer dos indicadores
   double wmaBuffer[], rviBuffer[], rviSignalBuffer[], 
      macdBuffer[], macdSignalBuffer[], closeBuffer[];
   
   //--- Copia os valores dos indicadores para seus respectivos buffers
   if (CopyBuffer(this.rviHandle, 0, 0, 2, rviBuffer) < 2
      || CopyBuffer(this.rviHandle, 1, 0, 2, rviSignalBuffer) < 2
      || CopyBuffer(this.macdHandle, 0, 0, 2, macdBuffer) < 2
      || CopyBuffer(this.macdHandle, 1, 0, 2, macdSignalBuffer) < 2
      || CopyBuffer(this.wmaHandle, 0, 0, 2, wmaBuffer) < 2
      || CopyClose(_Symbol, _Period, 0, 2, closeBuffer) < 2) {
      
      Print("Falha ao copiar os dados dos indicadores para os buffers! Erro ", GetLastError());
      return(sinal);
      
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(rviBuffer, true) 
      || !ArraySetAsSeries(rviSignalBuffer, true)
      || !ArraySetAsSeries(closeBuffer, true)
      || !ArraySetAsSeries(wmaBuffer, true)
      || !ArraySetAsSeries(macdBuffer, true)
      || !ArraySetAsSeries(macdSignalBuffer, true)) {
      
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
      
   }
   
   //--- Verifica se as linhas do RVI e do MACD cruzaram na mesma direção
   //--- Verifica também se o close da última barra está acima ou abaixo da WMA
   if (rviBuffer[1] > rviSignalBuffer[1] && macdBuffer[1] > macdSignalBuffer[1]
      && closeBuffer[1] > wmaBuffer[1]) {
      
      //--- Sinal de compra
      sinal = 1;
      
   } else if (rviBuffer[1] < rviSignalBuffer[1] && macdBuffer[1] < macdSignalBuffer[1]
      && closeBuffer[1] < wmaBuffer[1]) {
      
      //--- Sinal de venda
      sinal = -1;
      
   } else {
   
      //--- Sem sinal
      sinal = 0;
      
   }
      
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CFreelanceJob::sinalConfirmacao(int sinalNegociacao) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   //--- Armazena o buffer dos indicadores
   double wmaBuffer[], closeBuffer[];
   
   //--- Copia os valores dos indicadores para seus respectivos buffers
   if (CopyBuffer(this.wmaHighPeriodHandle, 0, 0, 2, wmaBuffer) < 2
      || CopyClose(_Symbol, _Period, 0, 2, closeBuffer) < 2) {
      
      Print("Falha ao copiar os dados dos indicadores para os buffers! Erro ", GetLastError());
      return(sinal);
      
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(closeBuffer, true)
      || !ArraySetAsSeries(wmaBuffer, true)) {
      
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
      
   }
   
   //--- Verifica se o close da última barra está acima ou abaixo da WMA
   if (sinalNegociacao == 1 && closeBuffer[1] > wmaBuffer[1]) {
   
      //--- Confirmado o sinal de compra
      sinal = 1;

   } else if (sinalNegociacao == -1 && closeBuffer[1] < wmaBuffer[1]) {
      
      //--- Confirmado o sinal de venda
      sinal = -1;

   } else {
   
      //--- Sem confirmação do sinal
      sinal = 0;
      
   }
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CFreelanceJob::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

double CFreelanceJob::obterStopLoss(ENUM_ORDER_TYPE tipoOrdem, double preco) {

   //--- Armazena o buffer do indicador ATR
   double atrBuffer[];
   
   //--- Copia os valores do indicador para seu respectivo buffer
   if (CopyBuffer(this.atrHandle, 0, 0, 2, atrBuffer) < 2) {
      
      Print("Falha ao copiar os dados dos indicadores para os buffers! Erro ", GetLastError());
      return(0);
      
   }
   
   //--- Define o buffer como série temporal
   if (!ArraySetAsSeries(atrBuffer, true)) {
      
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(0);
      
   }
   
   if (tipoOrdem == ORDER_TYPE_BUY) {
      //--- Define o stop loss para as ordens de compra
      return(preco - (atrBuffer[1] * 1.5));
   } else {
      //--- Define o stop loss para as ordens de venda
      return(preco + (atrBuffer[1] * 1.5));
   }

   return(0);
}

double CFreelanceJob::obterTakeProfit(ENUM_ORDER_TYPE tipoOrdem, double preco) {

   //--- Armazena o buffer do indicador ATR
   double atrBuffer[];
   
   //--- Copia os valores do indicador para seu respectivo buffer
   if (CopyBuffer(this.atrHandle, 0, 0, 2, atrBuffer) < 2) {
      
      Print("Falha ao copiar os dados dos indicadores para os buffers! Erro ", GetLastError());
      return(0);
      
   }
   
   //--- Define o buffer como série temporal
   if (!ArraySetAsSeries(atrBuffer, true)) {
      
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(0);
      
   }

   if (tipoOrdem == ORDER_TYPE_BUY) {
      //--- Define o take profit para as ordens de compra
      return(preco + atrBuffer[1]);
   } else {
      //--- Define o take profit para as ordens de venda
      return(preco - atrBuffer[1]);
   }

   return(0);
}

//+------------------------------------------------------------------+

/* Desde ponto em diante ficam as declarações das classes das estratégias
   declaradas neste arquivo MQH
*/

//--- Declaração de classes
CFreelanceJob cFreelanceJob;

//+------------------------------------------------------------------+