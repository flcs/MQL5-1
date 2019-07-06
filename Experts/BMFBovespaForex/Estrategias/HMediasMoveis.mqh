//+------------------------------------------------------------------+
//|                                                    HMediasMoveis |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Arquivo MQH que contém as estratégias para negociação utilizando médias móveis."

//--- Inclusão de arquivos
#include "..\\HStrategy.mqh"

//+------------------------------------------------------------------+
//| Classe CCruzamentoMACurtaAgil - Cruzamento Médias Móveis         |
//| MA Curta de 20 períodos, MA Ágil de 5 períodos                   |
//+------------------------------------------------------------------+
class CCruzamentoMACurtaAgil : public CStrategy {

   private:
      //--- Atributos
      int maAgilHandle;
      int maCurtaHandle;

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

int CCruzamentoMACurtaAgil::init(void) {
   
   //--- Inicializa os indicadores
   maAgilHandle = iMA(_Symbol, _Period, 5, 0, MODE_EMA, PRICE_CLOSE);
   maCurtaHandle = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (maAgilHandle < 0 || maCurtaHandle < 0) {
      Alert("Erro ao criar os indicadores! Erro ", GetLastError());
      return(INIT_FAILED);
   }
         
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
}

void CCruzamentoMACurtaAgil::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(maAgilHandle);
   IndicatorRelease(maCurtaHandle);
}

int CCruzamentoMACurtaAgil::sinalNegociacao(void) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double maAgilBuffer[], maCurtaBuffer[]; // Armazena os valores das médias móveis
   
   //--- Copia o valor dos indicadores para seus respectivos buffers
   if (CopyBuffer(maAgilHandle, 0, 0, 3, maAgilBuffer) < 3
         || CopyBuffer(maCurtaHandle, 0, 0, 3, maCurtaBuffer) < 3) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(maAgilBuffer, true) || !ArraySetAsSeries(maCurtaBuffer, true)) {
      Print("Falha ao definir os buffers como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica a MA das barras para determinar a tendência
   if (maAgilBuffer[2] < maCurtaBuffer[1] && maAgilBuffer[1] > maCurtaBuffer[1]) {
      // Tendência em alta
      sinal = 1;
   } else if (maAgilBuffer[2] > maCurtaBuffer[1] && maAgilBuffer[1] < maCurtaBuffer[1]) {
      // Tendência em baixa
      sinal = -1;
   } else {
      // Sem tendência
      sinal = 0;
   }

   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CCruzamentoMACurtaAgil::sinalConfirmacao(int sinalNegociacao) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   //--- Compara o sinal de negociação com o valor atual de suporte e resistência
   //--- do indicador NRTR
   
   //--- Tendência está a favor?
   if (sinalNegociacao == 1 && trailingStop.trend() == 1) {
      //--- Confirmado o sinal de compra
      sinal = 1;
   } else if (sinalNegociacao == -1 && trailingStop.trend() == -1) {
      //--- Confirmado o sinal de venda
      sinal = -1;
   }
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CCruzamentoMACurtaAgil::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CCruzamentoMACurtaAgil - Cruzamento Médias Móveis         |
//| MA Curta de 20 períodos, MA Longa de 50 períodos                 |
//+------------------------------------------------------------------+
class CCruzamentoMALongaCurta : public CStrategy {

   private:
      int maCurtaHandle;
      int maLongaHandle;

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

int CCruzamentoMALongaCurta::init(void) {
   
   maCurtaHandle = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   maLongaHandle = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (maCurtaHandle < 0 || maLongaHandle < 0) {
      Alert("Erro ao criar os indicadores! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CCruzamentoMALongaCurta::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(maCurtaHandle);
   IndicatorRelease(maLongaHandle);
}

int CCruzamentoMALongaCurta::sinalNegociacao(void) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double maCurtaBuffer[], maLongaBuffer[]; // Armazena os valores das médias móveis
   
   //--- Copia o valor dos indicadores para seus respectivos buffers
   if (CopyBuffer(maCurtaHandle, 0, 0, 3, maCurtaBuffer) < 3
         || CopyBuffer(maLongaHandle, 0, 0, 3, maLongaBuffer) < 3) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(maCurtaBuffer, true) || !ArraySetAsSeries(maLongaBuffer, true)) {
      Print("Falha ao definir os buffers como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica a MA das barras para determinar a tendência
   if (maCurtaBuffer[2] < maLongaBuffer[1] && maCurtaBuffer[1] > maLongaBuffer[1]) {
      // Tendência em alta
      sinal = 1;
   } else if (maCurtaBuffer[2] > maLongaBuffer[1] && maCurtaBuffer[1] < maLongaBuffer[1]) {
      // Tendência em baixa
      sinal = -1;
   } else {
      // Sem tendência
      sinal = 0;
   }

   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CCruzamentoMALongaCurta::sinalConfirmacao(int sinalNegociacao) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   //--- Compara o sinal de negociação com o valor atual de suporte e resistência
   //--- do indicador NRTR
   
   //--- Tendência está a favor?
   if (sinalNegociacao == 1 && trailingStop.trend() == 1) {
      //--- Confirmado o sinal de compra
      sinal = 1;
   } else if (sinalNegociacao == -1 && trailingStop.trend() == -1) {
      //--- Confirmado o sinal de venda
      sinal = -1;
   }
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CCruzamentoMALongaCurta::sinalSaidaNegociacao(int chamadaSaida) {

   //--- Verifica se a chamada veio do método OnTimer()
   if (chamadaSaida == 9) {
      //--- Verifica se o ativo atingiu o lucro desejado para poder encerrar a posição
      if (cMoney.atingiuLucroDesejado()) {
         return(0); // Pode encerrar as posições abertas
      }
   }

   return(-1);
}


//+------------------------------------------------------------------+
//| Classe CTendenciaNRTR - Sinais de negociação do NRTR com         |
//| com confirmação da tendência a partir da posição das barras em   |
//| relação a MA exponencial de 20 períodos.                         |
//+------------------------------------------------------------------+
class CTendenciaNRTR : public CStrategy {

   private:
      int maHandle;

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

int CTendenciaNRTR::init(void) {
   
   maHandle = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (maHandle < 0) {
      Alert("Erro ao criar os indicadores! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CTendenciaNRTR::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(maHandle);
}

int CTendenciaNRTR::sinalNegociacao(void) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   //--- Obtém o sinal de negociação com o valor atual de suporte e resistência
   //--- do indicador NRTR. O indicador já está instanciado pois o mesmo é usado
   //--- para trailing stop
   
   //--- Tendência está a favor?
   if (trailingStop.trend() == 1) {
      //--- Confirmado o sinal de compra
      sinal = 1;
   } else if (trailingStop.trend() == -1) {
      //--- Confirmado o sinal de venda
      sinal = -1;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CTendenciaNRTR::sinalConfirmacao(int sinalNegociacao) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double maBuffer[]; // Armazena os valores das médias móveis
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.maHandle, 0, 0, 4, maBuffer) < 4) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(maBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica qual posição da barra anterior em relação a MA curta para poder confirmar o sinal
   if (sinalNegociacao == 1) {
   
      if (maBuffer[1] < iOpen(_Symbol, _Period, 1) && maBuffer[1] < iClose(_Symbol, _Period, 1)
         && maBuffer[1] < iHigh(_Symbol, _Period, 1) && maBuffer[1] < iLow(_Symbol, _Period, 1)
         && maBuffer[2] < iOpen(_Symbol, _Period, 2) && maBuffer[2] < iClose(_Symbol, _Period, 2)
         && maBuffer[2] < iHigh(_Symbol, _Period, 2) && maBuffer[2] < iLow(_Symbol, _Period, 2)) {
         
         sinal = 1;
      
      }
   
   } else if (sinalNegociacao == -1) {

      if (maBuffer[1] > iOpen(_Symbol, _Period, 1) && maBuffer[1] > iClose(_Symbol, _Period, 1)
         && maBuffer[1] > iHigh(_Symbol, _Period, 1) && maBuffer[1] > iLow(_Symbol, _Period, 1)
         && maBuffer[2] > iOpen(_Symbol, _Period, 2) && maBuffer[2] > iClose(_Symbol, _Period, 2)
         && maBuffer[2] > iHigh(_Symbol, _Period, 2) && maBuffer[2] > iLow(_Symbol, _Period, 2)) {
         
         sinal = -1;
      
      }
   
   } else {
      //--- Sinal não confirmado
      sinal = 0;
   }
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CTendenciaNRTR::sinalSaidaNegociacao(int chamadaSaida) {

   //--- Esta estratégia gera bons resultados para Bitcoin e 
   //--- contrato cheio de índice sem qualquer controle de
   //--- encerramento de posições.
   //--- Caso algum outro ativo funcione bem com um controle 
   //--- de encerramento de posições, o mesmo será implementado
   //--- exclusivamente para este ativo.

   return(-1);
}
//+------------------------------------------------------------------+