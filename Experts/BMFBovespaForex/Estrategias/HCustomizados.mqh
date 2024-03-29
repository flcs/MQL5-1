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
//| Classe CPriceChannel - Sinais de negociação baseado no indicador |
//| customizado Price Channel.                                       |
//+------------------------------------------------------------------+
class CPriceChannel : public CStrategy {

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

int CPriceChannel::init(void) {

   this.customHandle = iCustom(_Symbol, _Period, "Artigos\\PriceChannel", 22);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.customHandle < 0) {
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CPriceChannel::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.customHandle);
}

int CPriceChannel::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   //--- Armazena os valores do indicador e o close das últimas barras
   double customBuffer1[], customBuffer2[], close[];
   
   //--- Copia os valores dos indicadores para seus respectivos buffers
   if (CopyBuffer(this.customHandle, 0, 0, 4, customBuffer1) < 4
      || CopyBuffer(this.customHandle, 1, 0, 4, customBuffer2) < 4
      || CopyClose(_Symbol, _Period, 0, 3, close) < 3) {
      Print("Falha ao copiar os dados dos indicadores para os buffers! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(customBuffer1, true) || !ArraySetAsSeries(customBuffer2, true)
      || !ArraySetAsSeries(close, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica os dados do indicador para determinar o sinal de negociação
   if (close[1] > customBuffer1[2]) {
      sinal = 1;
   } else if (close[1] < customBuffer2[2]) {
      sinal = -1;
   } else {
      sinal = 0;
   }
   
   //--- Caso o primeiro sinal seja zero, tenta uma segunda estratégia para gerar o sinal
   //--- de negociação
   if (sinal == 0) {
      if (close[1] > customBuffer2[2] && close[2] <= customBuffer2[3]) {
         sinal = 1;
      } else if (close[1] < customBuffer1[2] && close[2] >= customBuffer1[3]) {
         sinal = -1;
      } else {
         sinal = 0;
      }
   }
      
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CPriceChannel::sinalConfirmacao(int sinalNegociacao) {
   
   int sinal = sinalNegociacao;
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CPriceChannel::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe ForexAMA - Sinais de negociação baseado no Adaptive       |
//| Moving Average (AMA) usando as configurações padrão do indicador.|
//+------------------------------------------------------------------+
class CForexAMA : public CStrategy {

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

int CForexAMA::init(void) {

   this.amaHandle = iAMA(_Symbol, _Period, 9, 2, 30, 0, PRICE_CLOSE);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.amaHandle < 0) {
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CForexAMA::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.amaHandle);
}

int CForexAMA::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double amaBuffer[]; // Armazena os valores do indicador AMA
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.amaHandle, 0, 0, 4, amaBuffer) < 4) {
      Print("Falha ao copiar os dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(amaBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica os dados do indicador para determinar o sinal de negociação
   if (amaBuffer[3] < amaBuffer[2] && amaBuffer[2] < amaBuffer[1]) {
      sinal = 1;
   } else if (amaBuffer[3] > amaBuffer[2] && amaBuffer[2] > amaBuffer[1]) {
      sinal = -1;
   } else {
      sinal = 0;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CForexAMA::sinalConfirmacao(int sinalNegociacao) {
   
   int sinal = 0;
   
   /*
      Foi incluído confirmação de sinal baseado na posição do corpo da barra em relação a 
      AMA. O ganho é bem pequeno, mas já é um ganho.
   */
   
   //--- Para confirmar que o gráfico está mesmo em tendência, e não lateral, verifica
   //--- se a barra anterior (valores open e close) está acima ou abaixo da AMA
   
   double amaBuffer[]; // Armazena os valores das médias móveis
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.amaHandle, 0, 0, 2, amaBuffer) < 2) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(amaBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   if (sinalNegociacao == 1) {
      
      if (amaBuffer[1] < iOpen(_Symbol, _Period, 1) && amaBuffer[1] < iClose(_Symbol, _Period, 1)) {
         sinal = 1;
      }
   
   } else if (sinalNegociacao == -1) {

      if (amaBuffer[1] > iOpen(_Symbol, _Period, 1) && amaBuffer[1] > iClose(_Symbol, _Period, 1)) {
         sinal = -1;
      }
   
   } 
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CForexAMA::sinalSaidaNegociacao(int chamadaSaida) {
   
   /*
      Os backtesting feitos usando o lucro garantido mostraram que, apesar de eu ter um
      percentual elevado de negociações lucrativas, as perdas que eu obtive anulam os ganhos
      e ainda geram prejuízo. Ou seja, os lucros não cobrem as perdas. Este fato fica evidente
      quando comparei o resultado de AUDUSD de Jul-Dez/2008 sem controles com um teste com o 
      controle de lucro. O controle de prejuízo gerou muito mais perdas, apesar de mais de 70%
      das negociações fecharem com lucro.
   */
   
   
   //--- Verifica se a chamada veio do método OnTimer()
   //--- O lucro garantido foi ativado para poder operar na conta real
   if (chamadaSaida == 9) {
      //--- Verifica se o ativo atingiu o lucro desejado para poder encerrar a posição
      if (cMoney.atingiuLucroDesejado()) {
         return(0); // Pode encerrar as posições abertas
      }
   }
   
   
   /* Nos backtestings com AUDUSD utilizar o limite de prejuízo gerou bons ganhos durante o 
      período 2018-2019. Mas ao testar no período Jul-Dez/2008 gerou muitos prejuízos por 
      conta de muita oscilação do mercado, que acabou gerando muitas reversões e falsos sinais
      para a AMA. Até aumentando o valor limite, ainda gera prejuízo. Para o período de 2008 o 
      ideal é ter um recurso de reversão das posições, e/ou garantir o máximo de ganho possível
      para aguentar os stop loss.
   */
   
   if (chamadaSaida == 0) {
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
   }
   
   
   /*
      E usar ambas as estratégias não melhora muito os resultados referente ao período Jul-Dez/2008.
      Já quando comparamos com os resultados de 2018 até hoje, usar ambas as estratégias diminui
      as perdas obtidas quando usamos somente o lucro garantido, mas segue em desvantagem quando se
      compara com o controle de perda.
      Portanto, para a estratégia ForexAMA ficou o controle de perdas com o valor de 50.
   */
   
   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CTendenciaNRTR - Sinais de negociação do NRTR com         |
//| com confirmação da tendência a partir da posição das barras em   |
//| relação a MA exponencial de 20 períodos.                         |
//+------------------------------------------------------------------+
class CTendenciaNRTR : public CStrategy {

   private:
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

int CTendenciaNRTR::init(void) {

   //--- Inicializa as variáveis
   this.contNotificarUsuario = 0;
   
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

   //--- Verifica se a chamada veio do método OnTimer()
   if (chamadaSaida == 9) {
      //--- Verifica se o ativo atingiu o lucro desejado para poder encerrar a posição
      if (cMoney.atingiuLucroDesejado()) {
         return(0); // Pode encerrar as posições abertas
      }
   }
   
   if (chamadaSaida == 0) {
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
   }

   return(-1);
}

void CTendenciaNRTR::notificarUsuario(int sinalChamada) {
   
   //--- Notifica a cada 5 minutos das perdas financeiras
   if (sinalChamada == 9 && this.contNotificarUsuario == 5) {
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            double lucro = PositionGetDouble(POSITION_PROFIT);
            if (lucro <= -25) {
               //--- Envia uma mensage ao usuário informando do prejuízo
               cUtil.enviarMensagemUsuario("Ticket #" + IntegerToString(PositionGetTicket(i)) 
               + " do símbolo " + _Symbol + " está gerando prejuízo de " 
               + DoubleToString(PositionGetDouble(POSITION_PROFIT)) + "...");
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
//| Classe CTendenciaNRTRvolatile - Sinais de negociação do indicador|
//| customizado NRTR volatile, disponível na pasta                   |
//| Indicators/Artigos.                                              |
//+------------------------------------------------------------------+
class CTendenciaNRTRvolatile : public CStrategy {

   private:
      //--- Atributos
      int nrtrHandle;
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

int CTendenciaNRTRvolatile::init(void) {

   //--- Parâmetros: período = 12; k = 1
   this.nrtrHandle = iCustom(_Symbol, _Period, "Artigos\\NRTRvolatile", 12, 1);
   
   this.maHandle = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.nrtrHandle < 0 || maHandle < 0) {
      Alert("Erro ao criar os indicadores! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CTendenciaNRTRvolatile::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.nrtrHandle);
   IndicatorRelease(this.maHandle);
}

int CTendenciaNRTRvolatile::sinalNegociacao(void) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double upBuffer[], downBuffer[], signalUpBuffer[], signalDownBuffer[];
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.nrtrHandle, 2, 0, 1, upBuffer) < 1
      || CopyBuffer(this.nrtrHandle, 3, 0, 1, downBuffer) < 1
      || CopyBuffer(this.nrtrHandle, 0, 0, 1, signalUpBuffer) < 1
      || CopyBuffer(this.nrtrHandle, 1, 0, 1, signalDownBuffer) < 1) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(upBuffer, true) || !ArraySetAsSeries(downBuffer, true)
      || !ArraySetAsSeries(signalUpBuffer, true) || !ArraySetAsSeries(signalDownBuffer, true)) {
      Print("Falha ao definir os buffers como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica o sinal da tendência
   if (signalUpBuffer[0] > 0) {
      //--- Tendência em alta
      sinal = 1;
   } else if (signalDownBuffer[0] > 0) {
      //--- Tendência em baixa
      sinal = -1;
   } else {
      //--- Tendência não definida
      sinal = 0;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CTendenciaNRTRvolatile::sinalConfirmacao(int sinalNegociacao) {
   
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

int CTendenciaNRTRvolatile::sinalSaidaNegociacao(int chamadaSaida) {

   //--- Verifica se a chamada veio do método OnTimer()
   if (chamadaSaida == 9) {
   
      //--- Verifica se o ativo atingiu o lucro desejado para poder encerrar a posição
      if (cMoney.atingiuLucroDesejado()) {
         return(0); // Pode encerrar as posições abertas
      }
   }
   
   if (chamadaSaida == 0) {
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
   }

   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CDunnigan - Sinais de negociação do indicador Dunnigan.   |
//+------------------------------------------------------------------+
class CDunnigan : public CStrategy {

   private:
      int dunniganHandle;

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

int CDunnigan::init(void) {
   
   this.dunniganHandle = dunniganHandle = iCustom(_Symbol, _Period, "herculeshssj\\IDunnigan.ex5", 1); // Abertura/Fechamento
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.dunniganHandle < 0) {
      Alert("Erro ao criar os indicadores! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CDunnigan::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.dunniganHandle);
}

int CDunnigan::sinalNegociacao(void) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double vendaBuffer[], compraBuffer[];
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.dunniganHandle, 0, 0, 1, vendaBuffer) < 1
      || CopyBuffer(this.dunniganHandle, 1, 0, 1, compraBuffer) < 1) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(vendaBuffer, true) || !ArraySetAsSeries(compraBuffer, true)) {
      Print("Falha ao definir os buffers como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica os buffers de compra e venda para determinar a tendência da nova barra
   if (compraBuffer[0] > 0 && vendaBuffer[0] == 0) {
      //--- Sinal de compra
      sinal = 1;
   } else if (compraBuffer[0] == 0 && vendaBuffer[0] > 0) {
      //--- Sinal de venda
      sinal = -1;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CDunnigan::sinalConfirmacao(int sinalNegociacao) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   if (sinalNegociacao == 1) {
      sinal = 1;
   } else if (sinalNegociacao == -1) {
      sinal = -1;
   }
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CDunnigan::sinalSaidaNegociacao(int chamadaSaida) {

   //--- Verifica se a chamada veio do método OnTimer()
   if (chamadaSaida == 9) {
      //--- Verifica se o ativo atingiu o lucro desejado para poder encerrar a posição
      if (cMoney.atingiuLucroDesejado()) {
         return(0); // Pode encerrar as posições abertas
      }
   }
   
   if (chamadaSaida == 0) {
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
   }

   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CDunniganNRTR - Sinais de negociação do indicador         |
//| Dunnigan com confirmação através dos sinais do NRTRvolatile.     |
//+------------------------------------------------------------------+
class CDunniganNRTR : public CStrategy {

   private:
      //--- Atributos
      int dunniganHandle;
      int nrtrHandle;
      
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

int CDunniganNRTR::init(void) {
   
   //--- Parâmetro: Abertura/Fechamento
   this.dunniganHandle = iCustom(_Symbol, _Period, "herculeshssj\\IDunnigan", 1);
   
   //--- Parâmetros: período = 12; k = 1
   this.nrtrHandle = iCustom(_Symbol, _Period, "Artigos\\NRTRvolatile", 12, 1);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.dunniganHandle < 0 || this.nrtrHandle < 0) {
      Alert("Erro ao criar os indicadores! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CDunniganNRTR::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.dunniganHandle);
   IndicatorRelease(this.nrtrHandle);
}

int CDunniganNRTR::sinalNegociacao(void) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double vendaBuffer[], compraBuffer[];
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.dunniganHandle, 0, 0, 1, vendaBuffer) < 1
      || CopyBuffer(this.dunniganHandle, 1, 0, 1, compraBuffer) < 1) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(vendaBuffer, true) || !ArraySetAsSeries(compraBuffer, true)) {
      Print("Falha ao definir os buffers como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica os buffers de compra e venda para determinar a tendência da nova barra
   if (compraBuffer[0] > 0 && vendaBuffer[0] == 0) {
      //--- Sinal de compra
      sinal = 1;
   } else if (compraBuffer[0] == 0 && vendaBuffer[0] > 0) {
      //--- Sinal de venda
      sinal = -1;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CDunniganNRTR::sinalConfirmacao(int sinalNegociacao) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double upBuffer[], downBuffer[], signalUpBuffer[], signalDownBuffer[];
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.nrtrHandle, 2, 0, 1, upBuffer) < 1
      || CopyBuffer(this.nrtrHandle, 3, 0, 1, downBuffer) < 1
      || CopyBuffer(this.nrtrHandle, 0, 0, 1, signalUpBuffer) < 1
      || CopyBuffer(this.nrtrHandle, 1, 0, 1, signalDownBuffer) < 1) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(upBuffer, true) || !ArraySetAsSeries(downBuffer, true)
      || !ArraySetAsSeries(signalUpBuffer, true) || !ArraySetAsSeries(signalDownBuffer, true)) {
      Print("Falha ao definir os buffers como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   if (sinalNegociacao == 1 && (upBuffer[0] > 0 || signalUpBuffer[0] > 0)) {
      //--- Tendência em alta
      sinal = 1;
   } else if (sinalNegociacao == -1 && (downBuffer[0] > 0 || signalDownBuffer[0] > 0)) {
      //--- Tendência em baixa
      sinal = -1;
   } else {
      //--- Tendência não definida
      sinal = 0;
   }
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CDunniganNRTR::sinalSaidaNegociacao(int chamadaSaida) {

   //--- Verifica se a chamada veio do método OnTimer()
   if (chamadaSaida == 9) {
   
      //--- Verifica se o ativo atingiu o lucro desejado para poder encerrar a posição
      if (cMoney.atingiuLucroDesejado()) {
         return(0); // Pode encerrar as posições abertas
      }
   }
   
   if (chamadaSaida == 0) {
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
   }

   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CBuySellPressure - Sinais de negociação do indicador      |
//| customizado BuySellPressure. A ideia dessa estratégia é negociar |
//| quando a pressão de compra/venda atingir um determinado valor.   |
//+------------------------------------------------------------------+
class CBuySellPressure : public CStrategy {

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
      virtual double obterStopLoss(ENUM_ORDER_TYPE tipoOrdem, double preco);
      virtual double obterTakeProfit(ENUM_ORDER_TYPE tipoOrdem, double preco);       
      
      int onTickBarTimer(void) {
         return(0); // Novo tick
      }    

};

int CBuySellPressure::init(void) {

   this.customHandle = iCustom(_Symbol, _Period, "Downloads\\Buying_Selling_Pressure", 14, 4, 0, 3, 2);
   /* Parâmetros
   input uint                 InpPeriod   =  14;   // Period
   input uint                 InpPeriodSM =  4;    // Smoothing period
   input ENUM_MA_METHOD       InpMethodSM =  0;    // Smoothing method
   input ENUM_FILTER_TYPE_1   InpType1    =  3;    // Pressure filter
   input ENUM_FILTER_TYPE_2   InpType2    =  2;    // Smoothing filter
   */
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.customHandle < 0) {
      Alert("Erro ao criar os indicadores! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CBuySellPressure::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.customHandle);
}

int CBuySellPressure::sinalNegociacao(void) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   //--- Armazena os valores obtidos do indicador
   double buyBuffer[], sellBuffer[], sbuyBuffer[], ssellBuffer[];
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.customHandle, 0, 0, 1, buyBuffer) < 1
      || CopyBuffer(this.customHandle, 1, 0, 1, sellBuffer) < 1
      || CopyBuffer(this.customHandle, 4, 0, 1, sbuyBuffer) < 1
      || CopyBuffer(this.customHandle, 5, 0, 1, ssellBuffer) < 1) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   double buyPressure = NormalizeDouble(buyBuffer[0], _Digits);
   double sBuyPressure = NormalizeDouble(sbuyBuffer[0], _Digits);
   double sellPressure = NormalizeDouble(sellBuffer[0], _Digits);
   double sSellPressure = NormalizeDouble(ssellBuffer[0], _Digits);
   double valorAlvo = NormalizeDouble(100 * _Point, _Digits);
   
   //--- Verifica se os valores da pressão de compra/venda, tanto suavizado quanto não suavizado
   //--- são superiores a 100. Se for, abre uma nova posição de compra/venda.
   if ( buyPressure >= valorAlvo ) {
      
      //--- Sinal de compra
      sinal = 1;
     
   } else if ( sellPressure >= valorAlvo ) {
   
      //--- Sinal de venda
      sinal = -1;
   
   } else {
      //--- O volume de compra/venda não foi suficiente para abrir uma posição
      sinal = 0;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CBuySellPressure::sinalConfirmacao(int sinalNegociacao) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   sinal = sinalNegociacao;
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CBuySellPressure::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

//+------------------------------------------------------------------+
//| Retorna o valor do stop loss de acordo com os critérios definidos|
//| pela estratégia selecionada.                                     |
//+------------------------------------------------------------------+
double CBuySellPressure::obterStopLoss(ENUM_ORDER_TYPE tipoOrdem, double preco) {

   if (tipoOrdem == ORDER_TYPE_BUY) {
      //--- Define o stop loss para as ordens de compra
      return(preco - (300 * _Point));
   } else {
      //--- Define o stop loss para as ordens de venda
      return(preco + (300 * _Point));
   }

   return(0);
}

//+------------------------------------------------------------------+
//| Retorna o valor do take profit de acordo com os critérios        |
//| definidos pela estratégia selecionada.                           |
//+------------------------------------------------------------------+
double CBuySellPressure::obterTakeProfit(ENUM_ORDER_TYPE tipoOrdem, double preco) {

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

//+------------------------------------------------------------------+
//| Classe CInsideBar - Sinais de negociação baseado no padrão price |
//| action Inside Bar. Esta estratégia não faz uso de indicadores, e |
//| faz uso de uma esquema próprio de abertura de posições usando    |
//| ordens buy stop e sell stop.                                     |
//+------------------------------------------------------------------+
class CInsideBar : public CStrategy {

   public:
      //--- Métodos
      virtual int init(void);
      virtual void release(void);
      virtual int sinalNegociacao(void);
      virtual int sinalConfirmacao(int sinalNegociacao);
      virtual int sinalSaidaNegociacao(int chamadaSaida); 
      virtual double obterStopLoss(ENUM_ORDER_TYPE tipoOrdem, double preco);
      virtual double obterTakeProfit(ENUM_ORDER_TYPE tipoOrdem, double preco);       
      virtual void realizarNegociacao();
      
      int onTickBarTimer(void) {
         return(1); // Nova barra
      }    

};

int CInsideBar::init(void) {

   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CInsideBar::release(void) {
   
}

int CInsideBar::sinalNegociacao(void) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   //--- Seta o sinal de negociação com o valor -1
   sinal = -1;
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CInsideBar::sinalConfirmacao(int sinalNegociacao) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   //--- Mantém o sinal zero na confirmação
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CInsideBar::sinalSaidaNegociacao(int chamadaSaida) {
   return(-1);
}

double CInsideBar::obterStopLoss(ENUM_ORDER_TYPE tipoOrdem, double preco) {

   if (tipoOrdem == ORDER_TYPE_BUY) {
      //--- Define o stop loss para as ordens de compra
      return(preco - (300 * _Point));
   } else {
      //--- Define o stop loss para as ordens de venda
      return(preco + (300 * _Point));
   }

   return(0);
}

double CInsideBar::obterTakeProfit(ENUM_ORDER_TYPE tipoOrdem, double preco) {

   if (tipoOrdem == ORDER_TYPE_BUY) {
      //--- Define o take profit para as ordens de compra
      return(preco + (300 * _Point));
   } else {
      //--- Define o take profit para as ordens de venda
      return(preco - (300 * _Point));
   }

   return(0);
}

void CInsideBar::realizarNegociacao(void) {

   //--- Declaração de variáveis
   double open1,//first candle Open price
      open2,    //second candle Open price
      close1,   //first candle Close price
      close2,   //second candle Close price
      low1,     //first candle Low price
      low2,     //second candle Low price
      high1,    //first candle High price
      high2;    //second candle High price
      
   double buyPrice,//define BuyStop price
      buyTP,      //Take Profit BuyStop
      buySL,      //Stop Loss BuyStop
      sellPrice,  //define SellStop price
      sellTP,     //Take Profit SellStop
      sellSL;     //Stop Loss SellStop

   //--- Verifica se existem posições abertas
   if (cOrder.existePosicoesAbertas(POSITION_TYPE_BUY) || cOrder.existePosicoesAbertas(POSITION_TYPE_SELL)) {
      //--- Não abre nenhuma posição nova
   } else {
      
      /* A partir daqui começa a definição das ordens stop */
      
      //--- Obtém as informações do último preço da cotação
      MqlTick ultimoPreco;
      if (!SymbolInfoTick(_Symbol, ultimoPreco)) {
         Print("Erro ao obter a última cotação! - Erro ", GetLastError());
         return;
      }
      
      //--- Define os preçõs para as barras necessárias
      open1 = NormalizeDouble(iOpen(_Symbol, _Period, 1), _Digits);
      open2 = NormalizeDouble(iOpen(_Symbol, _Period, 2), _Digits);
      close1 = NormalizeDouble(iClose(_Symbol, _Period, 1), _Digits);
      close2 = NormalizeDouble(iClose(_Symbol, _Period, 2), _Digits);
      low1 = NormalizeDouble(iLow(_Symbol, _Period, 1), _Digits);
      low2 = NormalizeDouble(iLow(_Symbol, _Period, 2), _Digits);
      high1 = NormalizeDouble(iHigh(_Symbol, _Period, 1), _Digits);
      high2 = NormalizeDouble(iHigh(_Symbol, _Period, 2), _Digits);
      
      //--- Determina o tamanho da segunda barra
      double barSize=NormalizeDouble(((high2 - low2) / _Point), 0);
      
      //--- Define o valor do intervalo
      double interval = 20;
      
      //--- Define o valor do take profit
      double tp = 300;
      
      //--- Define a data de expiração das ordens
      datetime orderExpiration = TimeCurrent() + 48 * 60 * 60;
      
      //--- Se a segunda barra é grande o suficiente, então o mercado não está lateral.
      //--- E se a segunda barra é bullish, e a primeira barra é bearish;
      //--- E o high da segunda barra excede o high da primeira barra;
      //--- E o open da segunda barra excede o close da primeira barra;
      //--- E o low da segunda barra é menor que o low da primeira barra, então abre ordens stop de 
      //--- compra e venda
      if ( barSize > 800 && open2 > close2 && close1 > open1 && high2 > high1 && open2 > close1 && low2 < low1 ) {
         
         //--- Define o preço da ordem de compra considerando o intervalo
         buyPrice = NormalizeDouble(high2 + interval * _Point, _Digits);
         //--- Define o stop loss considerando o intervalo
         buySL = NormalizeDouble(low2 - interval * _Point, _Digits);
         //--- Define o take profit
         buyTP = NormalizeDouble(buyPrice + tp * _Point, _Digits);
         
         //--- Define o preço da ordem de venda considerando o intervalo
         sellPrice = NormalizeDouble(low2 - interval * _Point, _Digits);
         //--- Define o stop loss considerando o intervalo
         sellSL = NormalizeDouble(high2 + interval * _Point, _Digits);
         //--- Define o take profit
         sellTP = NormalizeDouble(sellPrice - tp * _Point, _Digits);
         
         //--- Envia a ordem buy stop
         cOrder.enviaOrdem(ORDER_TYPE_BUY_STOP, TRADE_ACTION_PENDING, buyPrice, cMoney.obterTamanhoLote(), buySL, buyTP, 2, 0, orderExpiration);
         
         //--- Envia a ordem sell stop
         cOrder.enviaOrdem(ORDER_TYPE_SELL_STOP, TRADE_ACTION_PENDING, sellPrice, cMoney.obterTamanhoLote(), sellSL, sellTP, 2, 0, orderExpiration);
         
      }
      
   }

}

//+------------------------------------------------------------------+

/* Desde ponto em diante ficam as declarações das classes das estratégias
   declaradas neste arquivo MQH
*/

//--- Declaração de classes
CPriceChannel cPriceChannel;
CTendenciaNRTR cTendenciaNRTR;
CTendenciaNRTRvolatile cTendenciaNRTRvolatile;
CDunnigan cDunnigan;
CDunniganNRTR cDunniganNRTR;
CForexAMA cForexAMA;
CBuySellPressure cBuySellPressure;
CInsideBar cInsideBar;

//+------------------------------------------------------------------+