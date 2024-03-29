//+------------------------------------------------------------------+
//|                                                     HAccount.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Classe com métodos utilitários para obter informações da conta."

//--- Inclusão de arquivos
#include "HUtil.mqh"

//--- Declaração de classes
CUtil cUtil; // Classe com métodos utilitários

//+------------------------------------------------------------------+
//| Classe CAccount - responsável por extrair informações sobre a    |
//| conta que o EA está operando.                                    |
//+------------------------------------------------------------------+
class CAccount {

   protected:
      //--- Atributos
      
      //--- Métodos
      double calculaMargemParaAberturaPosicoes(double tamanhoContrato, ENUM_POSITION_TYPE tipoPosicao);
      string obterSimboloPorMoedas(string moedaMargem, string moedaLucro);
      
   public:
      void CAccount() {};            // Construtor
      void ~CAccount() {};           // Construtor
      double calcularLucroPosicoesAbertas(void);
      double calcularPrejuizoPosicoesAbertas(void);
      void relatorioInformacoesConta(void);
      double obterMargemLivre();
      double obterMargemNecessariaParaNovaPosicao(double tamanhoContrato, ENUM_POSITION_TYPE tipoPosicao);
};

//+------------------------------------------------------------------+
//| Método que calcula o lucro obtido com todas as posições          |
//| lucrativas abertas para todos os ativos.                         |
//+------------------------------------------------------------------+
double CAccount::calcularLucroPosicoesAbertas(void) {
   
   double lucro = 0;
   
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetDouble(POSITION_PROFIT) > 0) {
         lucro += PositionGetDouble(POSITION_PROFIT);
      }
   }
   
   return lucro;  
}

//+------------------------------------------------------------------+
//| Método que calcula o prejuízo obtido com todas as posições       |
//| perdedoras abertas para todos os ativos.                         |
//+------------------------------------------------------------------+
double CAccount::calcularPrejuizoPosicoesAbertas(void) {

   double prejuizo = 0;
   
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetDouble(POSITION_PROFIT) <= 0) {
         prejuizo += PositionGetDouble(POSITION_PROFIT);
      }
   }
   
   return prejuizo;
}

//+------------------------------------------------------------------+
//| Retorna a margem livre da conta                                  |
//+------------------------------------------------------------------+
double CAccount::obterMargemLivre() {

   //--- Retorna a margem livre da conta
   return( AccountInfoDouble(ACCOUNT_MARGIN_FREE) );

}

//+------------------------------------------------------------------+
//| Retorna o valor de margem necessária para abrir uma nova posição |
//| do tamanho solicitado para o símbolo atual. O valor já considera |
//| a alavancagem da conta.                                          |
//+------------------------------------------------------------------+
double CAccount::obterMargemNecessariaParaNovaPosicao(double tamanhoContrato, ENUM_POSITION_TYPE tipoPosicao) {

   //--- Obtém o nível de alavancagem da conta
   int alavancagem = (int)AccountInfoInteger(ACCOUNT_LEVERAGE);
   
   //--- Calcula a margem necessária já considerando a alavancagem
   double margem = calculaMargemParaAberturaPosicoes(tamanhoContrato, tipoPosicao) / alavancagem;
   
   //--- Retorna o valor da margem
   return(margem);
}

//+------------------------------------------------------------------+
//| Retorna o valor da margem livre para abertura de novas posições. |
//| A função considera os pares de moeda reverso e cruzados, de      |
//| modo a informar com maior precisão de quanto realmente é preciso |
//| ter de margem livre na conta para poder negociar.                |
//|                                                                  |
//| Código obtido do artigo https://www.mql5.com/pt/articles/113     |
//+------------------------------------------------------------------+
double CAccount::calculaMargemParaAberturaPosicoes(double tamanhoContrato,ENUM_POSITION_TYPE tipoPosicao) {

   //--- Valor da margem
   double margem = 0;
   
   //--- Tamanho do contrato
   double tamanho = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   
   //--- Moeda da conta
   string moedaConta = AccountInfoString(ACCOUNT_CURRENCY);
   
   //--- Moeda da margem do ativo
   string moedaMargem = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_MARGIN);
   
   //--- Moeda de lucro do ativo
   string moedaLucro = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);
   
   //--- Moeda para o cálculo
   string moedaCalculo = "";
   
   //--- Cotação reversa - true; cotação direta - false
   bool mode; // Mantido o nome original da variável
   
   //--- Verifica se a moeda de lucro do ativo e da conta são iguais
   if (moedaLucro == moedaConta) {
      moedaCalculo = _Symbol;
      mode = true;
   }
   
   //--- Verifica se a moeda de margem do ativo e da conta são iguais
   if (moedaMargem == moedaConta) {
      moedaCalculo = _Symbol;
      
      // Retorna o valor do contrato multiplicado pelo tamanho desejado
      return(tamanho * tamanhoContrato);
   }

   //--- Se a moeda de cálculo continua indeterminada, então temos um par cruzado
   //--- de moedas
   if (moedaCalculo == "") {
      moedaCalculo = obterSimboloPorMoedas(moedaMargem, moedaConta);
      mode = true;
      
      //--- Se o valor obtido é nulo, então este símbolo não foi encontrado
      if (moedaCalculo == NULL) {
         //--- Vamos tentar do modo inverso
         moedaCalculo = obterSimboloPorMoedas(moedaConta, moedaMargem);
         mode = false;
      }
   }
   
   //--- Se mesmo assim o símbolo não foi encontrado, lança um erro geral na 
   //--- execução do EA. 
   if (moedaCalculo == "" || moedaCalculo == NULL) {
      Print(__FUNCTION__, ": Não foi possível determinar a moeda do ativo " + _Symbol + " e realizar o cálculo da margem!");
      return(NULL);
   }
   
   //--- Uma vez determinado a moeda de cálculo, vamos obter os últimos preços
   MqlTick tick;
   SymbolInfoTick(moedaCalculo, tick);
   
   //--- Agora podemos realizar os cálculos de margem
   double precoCalculo;
   
   //--- Calcula a margem para novas posições de compra
   if (tipoPosicao == POSITION_TYPE_BUY) {
      //--- Cotação reversa
      if (mode) {
         //--- Calcula usando o preço de compra para cotação reversa
         precoCalculo = tick.ask;
         margem = tamanho * tamanhoContrato * precoCalculo;
      } else {
         //--- Cotação direta
         
         //--- Calcula usando o preço de venda para a cotação direta
         precoCalculo = tick.bid;
         margem = tamanho * tamanhoContrato / precoCalculo;
         
      }
   }

   //--- Calcula a margem para novas posições de venda
   if (tipoPosicao == POSITION_TYPE_SELL) {
      //--- Cotação reversa
      if (mode) {
         //--- Calcula usando o preço de venda para cotação reversa
         precoCalculo = tick.bid;
         margem = tamanho * tamanhoContrato * precoCalculo;
      } else {
         //--- Cotação direta
         
         //--- Calcula usando o preço de compra para a cotação direta
         precoCalculo = tick.ask;
         margem = tamanho * tamanhoContrato / precoCalculo;
         
      }
   }
   
   //--- Retorna o montante necessário na moeda da conta para abrir a posição desejava
   //--- no volume especificado
   return(margem);
}

//+------------------------------------------------------------------+
//| Retorna o símbolo a partir da moeda da margem e lucro            |
//|                                                                  |
//| Código obtido do artigo https://www.mql5.com/pt/articles/113     |
//+------------------------------------------------------------------+
string CAccount::obterSimboloPorMoedas(string moedaMargem,string moedaLucro) {

   //--- Itera todos os símbolos que são mostrados na janela Market Watch (Observação do Mercado)
   for (int s = 0; s < SymbolsTotal(true); s++) {
      //--- Obtém o nome do símbolo
      string nomeSimbolo = SymbolName(s, true);
      
      //-- Obtém a moeda de margem do símbolo
      string moedaMargemSimbolo = SymbolInfoString(nomeSimbolo, SYMBOL_CURRENCY_MARGIN);
      
      //--- Obtém a moeda de lucro do símbolo
      string moedaLucroSimbolo = SymbolInfoString(nomeSimbolo, SYMBOL_CURRENCY_PROFIT);
      
      //--- Se o símbolo coincide com ambas as moedas, retorna o símbolo
      if (moedaMargemSimbolo == moedaMargem && moedaLucroSimbolo == moedaLucro) {
         return(nomeSimbolo);
      }
   }
   
   //--- Caso não encontre retorna NULL
   return(NULL);
}

//+------------------------------------------------------------------+
//| Relatório com todas as informações sobre a conta.                |
//+------------------------------------------------------------------+
void CAccount::relatorioInformacoesConta(void) {

   //--- Obtenção dos valores de enums
   ENUM_ACCOUNT_TRADE_MODE accountTradeMode = (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
   ENUM_ACCOUNT_STOPOUT_MODE accountStopOutMode = (ENUM_ACCOUNT_STOPOUT_MODE)AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE);
   ENUM_ACCOUNT_MARGIN_MODE accountMarginMode = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   bool thisAccountTradeAllowed = AccountInfoInteger(ACCOUNT_TRADE_ALLOWED);
   bool EATradeAllowed = AccountInfoInteger(ACCOUNT_TRADE_EXPERT);

   Print("***** INFORMAÇÕES GERAIS SOBRE A CONTA *****");
   
   //--- Exibe todas as informações disponíveis a partir da função AccountInfoString() 
   Print("Nome da corretora: ", AccountInfoString(ACCOUNT_COMPANY)); 
   Print("Moeda do depósito: ", AccountInfoString(ACCOUNT_CURRENCY)); 
   Print("Nome do cliente: ", AccountInfoString(ACCOUNT_NAME)); 
   Print("Nome do servidor comercial: ",AccountInfoString(ACCOUNT_SERVER)); 
   
   //--- Exibe todas as informações disponíveis a partir da função AccountInfoInteger()
   PrintFormat("Login (LOGIN): %d", AccountInfoInteger(ACCOUNT_LOGIN));
   PrintFormat("Alavancagem (LEVERAGE): 1:%I64d", AccountInfoInteger(ACCOUNT_LEVERAGE));
   switch(accountTradeMode) {
      case ACCOUNT_TRADE_MODE_REAL : PrintFormat("Modo de negociação da conta (TRADE_MODE): %s", "Conta real"); break;
      case ACCOUNT_TRADE_MODE_DEMO : PrintFormat("Modo de negociação da conta (TRADE_MODE): %s", "Conta demonstração"); break;
      case ACCOUNT_TRADE_MODE_CONTEST : PrintFormat("Modo de negociação da conta (TRADE_MODE): %s", "Conta competição/torneio"); break; 
   }
   PrintFormat("Número máximo de ordens pendentes (LIMIT_ORDERS): %d", AccountInfoInteger(ACCOUNT_LIMIT_ORDERS));
   switch(accountStopOutMode) {
      case ACCOUNT_STOPOUT_MODE_MONEY : PrintFormat("Modo da margem mínima permitida (MARGIN_SO_MODE): %s", "Dinheiro"); break;
      case ACCOUNT_STOPOUT_MODE_PERCENT : PrintFormat("Modo da margem mínima permitida (MARGIN_SO_MODE): %s", "Porcentagem"); break;
   }
   if (thisAccountTradeAllowed) {
      PrintFormat("Negociação permitida (TRADE_ALLOWED): %s", "Negociação permitida!");
   } else {
      PrintFormat("Negociação permitida (TRADE_ALLOWED): %s", "Negociação PROIBIDA!");
   }
   if (EATradeAllowed) {
      PrintFormat("Negociação permitida para Expert Advisor (TRADE_EXPERT): %s", "Negociação permitida para Expert Advisor!");
   } else {
      PrintFormat("Negociação permitida para Expert Advisor (TRADE_EXPERT): %s", "Negociação PROIBIDA para Expert Advisor!");
   }
   switch(accountMarginMode) {
      case ACCOUNT_MARGIN_MODE_EXCHANGE : PrintFormat("Modo de cálculo de margem (MARGIN_MODE): %s", "EXCHANGE"); break;
      case ACCOUNT_MARGIN_MODE_RETAIL_HEDGING : PrintFormat("Modo de cálculo de margem (MARGIN_MODE): %s", "RETAIL HEDGING"); break;
      case ACCOUNT_MARGIN_MODE_RETAIL_NETTING : PrintFormat("Modo de cálculo de margem (MARGIN_MODE): %s", "RETAIL NETTING"); break; 
   }
   PrintFormat("Número de casas decimais para a moeda da conta (CURRENCY_DIGITS): %d", AccountInfoInteger(ACCOUNT_CURRENCY_DIGITS));
   
   //--- Exibe todas as informações disponíveis a partir da função AccountInfoDouble()
   PrintFormat("Saldo da conta (BALANCE): %G", AccountInfoDouble(ACCOUNT_BALANCE));
   PrintFormat("Crédito da conta (CREDIT): %G", AccountInfoDouble(ACCOUNT_CREDIT));
   PrintFormat("Lucro atual (PROFIT): %G", AccountInfoDouble(ACCOUNT_PROFIT));
   PrintFormat("Saldo a mercado (EQUITY): %G", AccountInfoDouble(ACCOUNT_EQUITY));
   PrintFormat("Margem usada (MARGIN): %G", AccountInfoDouble(ACCOUNT_MARGIN));
   PrintFormat("Margem livre (MARGIN_FREE): %G", AccountInfoDouble(ACCOUNT_MARGIN_FREE));
   PrintFormat("Nível de margem (MARGIN_LEVEL): %G %s", AccountInfoDouble(ACCOUNT_MARGIN_LEVEL), "%");
   switch(accountStopOutMode) {
      case ACCOUNT_STOPOUT_MODE_MONEY : PrintFormat("Nível de chamada de margem (MARGIN_SO_CALL): %G", AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL)); break;
      case ACCOUNT_STOPOUT_MODE_PERCENT : PrintFormat("Nível de chamada de margem (MARGIN_SO_CALL): %G %s", AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL), "%"); break;
   }
   switch(accountStopOutMode) {
      case ACCOUNT_STOPOUT_MODE_MONEY : PrintFormat("Nível de margem de Stop Out - encerramento forçado (MARGIN_SO_SO): %G", AccountInfoDouble(ACCOUNT_MARGIN_SO_SO)); break;
      case ACCOUNT_STOPOUT_MODE_PERCENT : PrintFormat("Nível de margem de Stop Out - encerramento forçado (MARGIN_SO_SO): %G %s", AccountInfoDouble(ACCOUNT_MARGIN_SO_SO), "%"); break;
   }
   PrintFormat("Margem inicial (MARGIN_INITIAL): %G", AccountInfoDouble(ACCOUNT_MARGIN_INITIAL));
   PrintFormat("Margem de manutenção (MARGIN_MAINTENANCE): %G", AccountInfoDouble(ACCOUNT_MARGIN_MAINTENANCE));
   PrintFormat("Ativos atuais (ASSETS): %G", AccountInfoDouble(ACCOUNT_ASSETS));
   PrintFormat("Responsabilidades atuais (LIABILITIES): %G", AccountInfoDouble(ACCOUNT_LIABILITIES));
   PrintFormat("Comissão bloqueada (COMMISION_BLOCKED): %G", AccountInfoDouble(ACCOUNT_COMMISSION_BLOCKED));
      
   Print("***** FIM DO RELATÓRIO *****");
}
//+------------------------------------------------------------------+