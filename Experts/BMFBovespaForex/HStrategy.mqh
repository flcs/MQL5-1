//+------------------------------------------------------------------+
//|                                                    HStrategy.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Arquivo MQH que contém as definições para as estratégias de negociação nos mercados BM&FBovespa e Forex."

//--- Inclusão de arquivos
#include "HTrailingStop.mqh"

//--- Enumerações
//--- Ordem: 1º - estratégias específicas; 2º - tendência; 3º - osciladores; 4º - indicadores exóticos.
enum ESTRATEGIA_NEGOCIACAO {
   BMFBOVESPA_FOREX, // BM&FBovespa e Forex
   TENDENCIA_NRTR, // Tendência NRTR
   TENDENCIA_NRTRVOLATILE, // Tendência NRTR volatile
   DUNNIGAN, // Dunnigan
   DUNNIGAN_NRTR, // Dunnigan + NRTR volatile
   FOREX_AMA, // Forex - AMA
   FOREX_XAUAUD, // Forex - XAUAUD
   FOREX_XAUUSD, // Forex - XAUUSD
   FOREX_XAUEUR, // Forex - XAUEUR
   MINICONTRATO_INDICE, // Minicontrato Índice   
   CRUZAMENTO_MA_CURTA_AGIL, // Cruzamento MA Curta-Ágil
   CRUZAMENTO_MA_LONGA_CURTA, // Cruzamento MA Longa-Curta
   ADX_MA, // Sinal ADX + MA exponencial
   ADAPTIVE_CHANNEL_ADX, // Adaptive Channel ADX
   BOLLINGER_BANDS, // Bollinger Bands
   ENVELOPES, // Envelopes
   ICHIMOKU_KINKO_HYO, // Ichimoku Kinko Hyo
   CANAL_DESVIO_PADRAO, // Canal Desvio Padrão
   CANAL_DONCHIAN, // Canal Donchian
   SILVER_CHANNEL, // Silver Channel
   PRICE_CHANNEL_GALLAHER, // Price Channel Gallaher
   SINAL_AMA, // Sinal AMA
   SINAL_ATR, // Sinal ATR
   SINAL_CCI, // Sinal CCI
   SINAL_MACD, // Sinal MACD
   SINAL_RSI, // Sinal RSI
   SINAL_ESTOCASTICO, // Sinal Estocástico
   SINAL_ALLIGATOR, // Sinal Alligator
   SINAL_AWESOME, // Sinal Awesome Oscillator
   SINAL_WPR, // Sinal Williams (%)
   BUY_SELL_PRESSURE, // Buy/Sell Pressure
   INSIDE_BAR, // Inside Bar
   TABAJARA, // Indicador Tabajara
   PRICE_CHANNEL, // Price Channel
   FREELANCE_JOB // Trabalho Freelance
};

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
   //--- O método recebe uma chamada de saída, informando qual método fez a chamada para 
   //--- verificar o fechamento das posições abertas.
   //--- 0 - novo tick
   //--- 1 - nova barra
   //--- 9 - novo ciclo no timer
   int sinalSaidaNegociacao(int chamadaSaida);
   
   //--- Método que envia uma mensagem para o usuário. Esta mensagem pode ser disparada
   //--- quando ocorrer os seguinte eventos:
   //--- 0 - novo tick
   //--- 1 - nova barra
   //--- 9 - novo ciclo no timer
   //--- A variável 'sinalChamada' é reponsável por identificar o evento que disparou a 
   //--- notificação ao usuário.
   void notificarUsuario(int sinalChamada);
   
   //--- Método que retorna o valor para o stop loss de acordo com os critérios
   //--- da estratégia
   double obterStopLoss(ENUM_ORDER_TYPE tipoOrdem, double preco);
   
   //--- Método que retorna o valor para o take profit de acordo com os critérios
   //--- da estratégia
   double obterTakeProfit(ENUM_ORDER_TYPE tipoOrdem, double preco);
   
   //--- Método que efetua a abertura de novas posições e/ou fechamento das posições
   //--- existentes de acordo com a estratégia definida. Este método é útil para poder
   //--- realizar aberturas de ordens limit e stop, as ordens padrão do EA são a mercado
   void realizarNegociacao();
};

//+------------------------------------------------------------------+
//| Classe CStrategy - classe abstrata que reúne as definições gerais|
//| para as demais classes de estratégia.                            |
//+------------------------------------------------------------------+
class CStrategy : public IStrategy {

   public:
      //--- Inicialização das variáveis privadas e dos indicadores
      virtual int init(void);
      
      //--- Desalocação das variáveis privadas e dos indicadores
      virtual void release(void);
      
      //--- Informa que a estratégia opera após a chegada de um novo tick, ou após
      //--- uma nova barra, ou após a contagem do timer
      //--- 0 - novo tick
      //--- 1 - nova barra
      //--- 9 - timer
      virtual int onTickBarTimer(void) {
         //--- Por padrão retorna 1
         return(1);
      }
      
      virtual void notificarUsuario(int sinalChamada) {
         //--- Por padrão imprime uma mensagem no console
         cUtil.enviarMensagem(CONSOLE, "Uma notificação foi enviada ao usuário.");
      }
      
      virtual double obterStopLoss(ENUM_ORDER_TYPE tipoOrdem, double preco) {
         //--- Por padrão o valor do stop loss é zero
         return(0);
      }
      
      virtual double obterTakeProfit(ENUM_ORDER_TYPE tipoOrdem, double preco) {
         //--- Por padrão o valor do take profit é zero
         return(0);
      }
      
      virtual void realizarNegociacao() {
         //--- Por padrão o método não tem nenhum código.
      }
};

//+------------------------------------------------------------------+