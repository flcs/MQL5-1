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
   MINICONTRATO_INDICE, // Minicontrato Índice   
   CRUZAMENTO_MA_CURTA_AGIL, // Cruzamento MA Curta-Ágil
   CRUZAMENTO_MA_LONGA_CURTA, // Cruzamento MA Longa-Curta
   ADX_MA, // Sinal ADX + MA exponencial
   SINAL_ATR, // Sinal ATR
   SINAL_MACD, // Sinal MACD
   SINAL_ESTOCASTICO // Sinal Estocástico
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
};

//+------------------------------------------------------------------+