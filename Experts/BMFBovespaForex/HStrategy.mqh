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
enum ESTRATEGIA_NEGOCIACAO {
   CRUZAMENTO_MA_CURTA_AGIL, // Cruzamento MA Curta-Ágil
   CRUZAMENTO_MA_LONGA_CURTA, // Cruzamento MA Longa-Curta
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
   int sinalSaidaNegociacao(void);
   
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
      
};

//+------------------------------------------------------------------+