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

   //--- Verifica o tamanho do prejuízo para poder encerrar as posições
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         double lucro = PositionGetDouble(POSITION_PROFIT);
         if (lucro <= -50) {
            //--- Encerra a posição quando o prejuízo alcançar o limite máximo estabelecido
            return(0); // Pode encerrar as posições abertas
         }
      }
   }

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

//+------------------------------------------------------------------+
//| Classe CTabajara - Estratégia de negociação usando o indicador   |
//| Tabajara.                                                        |
//+------------------------------------------------------------------+
class CTabajara : public CStrategy {

   private:
      //--- Atributos
      int customHandle;

   public:
      //--- Métodos
      virtual int init(void);
      virtual void release(void);
      virtual int sinalNegociacao(void);
      virtual int sinalConfirmacao(int sinalNegociacao);
      virtual int sinalSaidaNegociacao(int chamadaSaida);
      virtual double obterTakeProfit(ENUM_ORDER_TYPE tipoOrdem, double preco);
      virtual double obterStopLoss(ENUM_ORDER_TYPE tipoOrdem, double preco);

};

int CTabajara::init(void) {

   // Inicializa o indicador
   this.customHandle = iCustom(_Symbol, _Period, "Downloads\\tabajaraclassico1.01.ex5", 20, MODE_SMA);
   
   //--- Verifica se o indicador foi criado com sucesso
   if (this.customHandle == INVALID_HANDLE) {
      Alert("Erro ao criar os indicadores! Erro ", GetLastError());
      return(INIT_FAILED);
   }
         
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
}

void CTabajara::release(void) {
   //--- Libera o indicador
   IndicatorRelease(this.customHandle);
}

int CTabajara::sinalNegociacao(void) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double maBuffer1[], maBuffer2[]; // Armazena os valores do indicador
   
   //--- Copia o valor do indicador para seus respectivos buffers
   if (CopyBuffer(this.customHandle, 1, 0, 2, maBuffer1) < 2
         || CopyBuffer(this.customHandle, 6, 0, 2, maBuffer2) < 2) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(maBuffer1, true) || !ArraySetAsSeries(maBuffer2, true)) {
      Print("Falha ao definir os buffers como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica o valor dos buffer para obter o sinal de negociação.
   if (maBuffer1[1] == 1 || maBuffer2[1] == 1) {
      // Tendência em alta
      sinal = 1;
   } else if (maBuffer1[1] == 0 || maBuffer2[1] == 0) {
      // Tendência em baixa
      sinal = -1;
   } else {
      // Sem tendência
      sinal = 0;
   }

   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CTabajara::sinalConfirmacao(int sinalNegociacao) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   sinal = sinalNegociacao;
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CTabajara::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

double CTabajara::obterStopLoss(ENUM_ORDER_TYPE tipoOrdem, double preco) {

   if (tipoOrdem == ORDER_TYPE_BUY) {
      //--- Define o stop loss para as ordens de compra
      return(preco - (300 * _Point));
   } else {
      //--- Define o stop loss para as ordens de venda
      return(preco + (300 * _Point));
   }

   return(0);
}

double CTabajara::obterTakeProfit(ENUM_ORDER_TYPE tipoOrdem, double preco) {

   if (tipoOrdem == ORDER_TYPE_BUY) {
      //--- Define o take profit para as ordens de compra
      return(preco + (300 * _Point));
   } else {
      //--- Define o take profit para as ordens de venda
      return(preco - (300 * _Point));
   }

   return(0);
}

//+------------------------------------------------------------------+

/* Desde ponto em diante ficam as declarações das classes das estratégias
   declaradas neste arquivo MQH
*/

//--- Declaração de classes
CCruzamentoMACurtaAgil cCruzamentoMACurtaAgil;
CCruzamentoMALongaCurta cCruzamentoMALongaCurta;
CTabajara cTabajara;

//+------------------------------------------------------------------+