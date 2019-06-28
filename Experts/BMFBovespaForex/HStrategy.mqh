//+------------------------------------------------------------------+
//|                                                       HStrategyh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Arquivo MQH que contém as estratégias para negociação nos mercados BM&FBovespa e Forex."

//--- Inclusão de arquivos
#include "HTrailingStop.mqh"

//--- Enumerações
enum ESTRATEGIA_NEGOCIACAO {
   CRUZAMENTO_MA_CURTA_AGIL, // Cruzamento MA Curta-Ágil
   CRUZAMENTO_MA_LONGA_CURTA // Cruzamento MA Longa-Curta
};

//--- Variáveis estáticas

//--- Declaração de classes
CNRTRStop trailingStop; // Classe para stop móvel usando os sinais do indicador NRTR

//+------------------------------------------------------------------+
//| Interface IStrategy - interface que define os principais métodos |
//| de uma estratégia para negociação.                               |
//+------------------------------------------------------------------+
interface IStrategy {
   
   //--- Método que obtém os sinais para abrir novas posições de compra/venda
   //--- -1 - Sinal de venda
   //--- 0 - Sem sinal, não abre uma posição
   //--- 1 - Sinal de compra
   int sinalNegociacao(void);
   
   //--- Método que obtém sinais para confirmar a abertura novas posições de compra/venda
   //--- -1 - Confirma o sinal de venda
   //--- 0 - Sem sinal, não confirma a abertura da posição
   //--- 1 - Confirma o sinal de compra
   int sinalConfirmacao(int sinalNegociacao);
   
   //--- Método que obtém um sinal para efetuar a saída das posições abertas
   //--- 0 - Confirma a saída da posição
   //--- -1 - manter a posição
   int sinalSaidaNegociacao(void);
   
};

//+------------------------------------------------------------------+
//| Classe CStrategy - classe abstrata que reúne as definições gerais|
//| para as demais classes de estratégia.                            |
//+------------------------------------------------------------------+
class CStrategy : public IStrategy {

   private:
      //--- Atributos
      
      //--- Métodos

   protected:
      //--- Atributos

            
      //--- Métodos
      
   public:
      //--- Atributos
            
      //--- Inicialização das variáveis privadas e dos indicadores
      virtual int init(void);
      
      //--- Desalocação das variáveis privadas e dos indicadores
      virtual void release(void);
      
};

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CCruzamentoMACurtaAgil - Cruzamento Médias Móveis         |
//| MA Curta de 20 períodos, MA Ágil de 5 períodos                   |
//+------------------------------------------------------------------+
class CCruzamentoMACurtaAgil : public CStrategy {

   private:
      int maAgilHandle;
      int maCurtaHandle;

   public:
      //--- Métodos
      virtual int init(void);
      virtual void release(void);
      virtual int sinalNegociacao(void);
      virtual int sinalConfirmacao(int sinalNegociacao);
      virtual int sinalSaidaNegociacao(void);

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

int CCruzamentoMACurtaAgil::sinalSaidaNegociacao(void) {
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
      virtual int sinalSaidaNegociacao(void);      

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

int CCruzamentoMALongaCurta::sinalSaidaNegociacao(void) {
   return(-1);
}

//+------------------------------------------------------------------+