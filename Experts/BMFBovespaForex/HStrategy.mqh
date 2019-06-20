//+------------------------------------------------------------------+
//|                                                       HStrategyh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Classe que contém as estratégias para negociação nos mercados BM&FBovespa e Forex."

//--- Inclusão de arquivos
#include "HTrailingStop.mqh"

CNRTRStop trailingStop; // Classe para stop móvel usando os sinais do indicador NRTR

//+------------------------------------------------------------------+
//| Classe CStrategy - classe que reúne as estratégias de negociação.|
//+------------------------------------------------------------------+
class CStrategy {

   protected:
      //--- Atributos
      int maCurtaHandle;
      int maLongaHandle;
      ENUM_SYMBOL_CALC_MODE mercadoAOperar;
            
      //--- Métodos
      
   public:
      //--- Atributos
      
      //--- Métodos
      void CStrategy() {}; // Construtor
      void ~CStrategy() {}; // Destrutor
      
      int init();
      void release();
      int estrategiaBovespa(void);
      int estrategiaForex(void);
      int confirmarSinalNegociacaoForex(int sinalNegociacao);
      int confirmarSinalNegociacaoBovespa(int sinalNegociacao);
      
};

int CStrategy::init() {

   this.mercadoAOperar = (ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);

   //--- Verifica qual mercado que o EA está operando para selecionar corretamente a estratégia
   switch (this.mercadoAOperar) {
      case SYMBOL_CALC_MODE_EXCH_FUTURES:
      
         maCurtaHandle = iMA(_Symbol, _Period, 5, 0, MODE_EMA, PRICE_CLOSE);
         maLongaHandle = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
         
         //--- Verifica se os indicadores foram criados com sucesso
         if (maCurtaHandle < 0 || maLongaHandle < 0) {
            Alert("Erro ao criar os indicadores! Erro ", GetLastError());
            return(INIT_FAILED);
         }
         
         //--- Retorna o sinal de sucesso
         return(INIT_SUCCEEDED);
         
         break;
      case SYMBOL_CALC_MODE_FOREX:
      
         maCurtaHandle = iMA(_Symbol, _Period, 5, 0, MODE_EMA, PRICE_CLOSE);
         maLongaHandle = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
         
         //--- Verifica se os indicadores foram criados com sucesso
         if (maCurtaHandle < 0 || maLongaHandle < 0) {
            Alert("Erro ao criar os indicadores! Erro ", GetLastError());
            return(INIT_FAILED);
         }
         
         //--- Retorna o sinal de sucesso
         return(INIT_SUCCEEDED);
         
         break;
   }
   
   return(INIT_FAILED);
}

void CStrategy::release(void) {
   
   //--- Libera os indicadores
   switch (this.mercadoAOperar) {
      case SYMBOL_CALC_MODE_EXCH_FUTURES:
         IndicatorRelease(maCurtaHandle);
         IndicatorRelease(maLongaHandle);
         break;
      case SYMBOL_CALC_MODE_FOREX:
         IndicatorRelease(maCurtaHandle);
         IndicatorRelease(maLongaHandle);         
         break;
   }
}

//+------------------------------------------------------------------+
//| Estratégia para obter sinais de negociação na BM&FBovespa        |
//|                                                                  |
//|  -1 - Sinal para abertura de uma posição de venda                |
//|  +1 - Sinal para abertura de uma posição de compra               |
//|   0 - Nenhum posição será aberta                                 |
//+------------------------------------------------------------------+
int CStrategy::estrategiaBovespa(void) {

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

//+------------------------------------------------------------------+
//| Estratégia para obter sinais de negociação no mercado Forex      |
//|                                                                  |
//|  -1 - Sinal para abertura de uma posição de venda                |
//|  +1 - Sinal para abertura de uma posição de compra               |
//|   0 - Nenhum posição será aberta                                 |
//+------------------------------------------------------------------+
int CStrategy::estrategiaForex(void) {

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

//+------------------------------------------------------------------+
//|  Função responsável por confirmar se o momento é de abrir uma    |
//|  posição de compra ou venda. Esta função é chamada sempre que se |
//|  obter a confirmação do sinal a partir de outro indicador ou     |
//|  outra forma de cálculo.                                         |
//|                                                                  |
//|  -1 - Confirma a abertura da posição de venda                    |
//|  +1 - Confirma a abertura da posição de compra                   |
//|   0 - Informa que nenhuma posição deve ser aberta                |
//+------------------------------------------------------------------+
int CStrategy::confirmarSinalNegociacaoBovespa(int sinalNegociacao) {
   
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

//+------------------------------------------------------------------+
//|  Função responsável por confirmar se o momento é de abrir uma    |
//|  posição de compra ou venda. Esta função é chamada sempre que se |
//|  obter a confirmação do sinal a partir de outro indicador ou     |
//|  outra forma de cálculo.                                         |
//|                                                                  |
//|  -1 - Confirma a abertura da posição de venda                    |
//|  +1 - Confirma a abertura da posição de compra                   |
//|   0 - Informa que nenhuma posição deve ser aberta                |
//+------------------------------------------------------------------+
int CStrategy::confirmarSinalNegociacaoForex(int sinalNegociacao) {

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