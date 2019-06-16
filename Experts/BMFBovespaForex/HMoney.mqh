//+------------------------------------------------------------------+
//|                                                       HMoney.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Classe com métodos utilitários para gerenciamento financeiro da conta."

//--- Inclusão de arquivos
#include "HAccount.mqh"

//--- Declaração de classes
CAccount cAccount; // Classe com métodos para obter informações sobre a conta

//+------------------------------------------------------------------+
//| Classe CMoney - responsável por gerenciar os recursos financeiros|
//| disponíveis na conta.                                            |
//+------------------------------------------------------------------+
class CMoney {
      
   public:
      void CMoney() {};            // Construtor
      void ~CMoney() {};           // Construtor
};