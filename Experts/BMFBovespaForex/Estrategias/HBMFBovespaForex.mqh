//+------------------------------------------------------------------+
//|                                             HBMFBovespaForex.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Arquivo MQH que contém a estratégias para negociação nos mercados BM&FBovespa e Forex."

//--- Inclusão de arquivos
#include "..\\HStrategy.mqh"

//+------------------------------------------------------------------+
//| Classe CBMFBovespaForex - Sinais de negociação baseado no        |
//| cruzamento de MAs de 5 e 20 períodos, e também do oscilador      |
//| estocástico. Os dois indicadores dão sinais de negociação, que   |
//| são confirmados pelo NRTR e a posição da barra anterior em       |
//| relação a MA exponencial de 20 períodos, evitando assim abertura |
//| de novas posições contrários a tendência.                        |
//+------------------------------------------------------------------+
class CBMFBovespaForex : public CStrategy {

   private:
      int estocasticoHandle;
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

int CBMFBovespaForex::init(void) {

   maAgilHandle = iMA(_Symbol, _Period, 5, 0, MODE_EMA, PRICE_CLOSE);
   maCurtaHandle = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   estocasticoHandle = iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (maAgilHandle < 0 || maCurtaHandle < 0 || estocasticoHandle < 0) {
      Alert("Erro ao criar os indicadores! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CBMFBovespaForex::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(maAgilHandle);
   IndicatorRelease(maCurtaHandle);
   IndicatorRelease(estocasticoHandle);
}

int CBMFBovespaForex::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double maAgilBuffer[], maCurtaBuffer[]; // Armazena os valores das médias móveis
   double estocasticoBuffer[]; // Armazena os valores do oscilador estocástico
   
   //--- Copia o valor dos indicadores para seus respectivos buffers
   if (CopyBuffer(maAgilHandle, 0, 0, 3, maAgilBuffer) < 3
         || CopyBuffer(maCurtaHandle, 0, 0, 3, maCurtaBuffer) < 3) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(estocasticoHandle, 0, 0, 3, estocasticoBuffer) < 3) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(maAgilBuffer, true) || !ArraySetAsSeries(maCurtaBuffer, true)) {
      Print("Falha ao definir os buffers como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(estocasticoBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
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
   
   //--- Caso o sinal gerado pelas MAs seja zero, obtém-se o sinal de negociação do 
   //--- estocástico
   if (sinal == 0) {
      if (estocasticoBuffer[2] < 20 && estocasticoBuffer[1] > 20) {
         sinal = 1;
      } else if (estocasticoBuffer[2] > 80 && estocasticoBuffer[1] < 80) {
         sinal = -1;
      } else {
         sinal = 0;
      }
   }
   
   //--- Caso nenhum sinal tenha sido gerado, usa-se o NRTR para gerar o sinal de negociação
   if (sinal == 0) {
      if (trailingStop.trend() == 1) {
         //--- Confirmado o sinal de compra
         sinal = 2;
      } else if (trailingStop.trend() == -1) {
         //--- Confirmado o sinal de venda
         sinal = -2;
      } else {
         sinal = 0;
      }
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CBMFBovespaForex::sinalConfirmacao(int sinalNegociacao) {
   
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
   
   //--- Para confirmar que o gráfico está mesmo em tendência, e não lateral, verifica
   //--- se a barra anterior está acima ou abaixo da MA curta
   
   double maBuffer[]; // Armazena os valores das médias móveis
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.maCurtaHandle, 0, 0, 4, maBuffer) < 4) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(maBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   if (sinalNegociacao == 2) {
      
      if (maBuffer[1] < iOpen(_Symbol, _Period, 1) && maBuffer[1] < iClose(_Symbol, _Period, 1)
         && maBuffer[1] < iHigh(_Symbol, _Period, 1) && maBuffer[1] < iLow(_Symbol, _Period, 1)) {
         
         sinal = 1;
      
      }
   
   } else if (sinalNegociacao == -2) {

      if (maBuffer[1] > iOpen(_Symbol, _Period, 1) && maBuffer[1] > iClose(_Symbol, _Period, 1)
         && maBuffer[1] > iHigh(_Symbol, _Period, 1) && maBuffer[1] > iLow(_Symbol, _Period, 1)) {
         
         sinal = -1;
      
      }
   
   } else {
      //--- Sinal não confirmado
      sinal = 0;
   }
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CBMFBovespaForex::sinalSaidaNegociacao(int chamadaSaida) {
   
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