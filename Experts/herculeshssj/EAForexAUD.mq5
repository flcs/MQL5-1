//+------------------------------------------------------------------+
//|                                                   EAForexAUD.mq5 |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|Changelog:                                                        |
//|v1.00 - Versão inicial baseado no EAArtificialIntelligence.mq5. A |
//|        parte que usava a rede neural perceptron foi substituída  |
//|        por sinais de compra e venda de outros indicadores.       |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property version   "1.00"
#property description "EA projetado para trabalhar no mercado Forex usando os pares de moeda AUD"

//--- Include files
#include <Trade\Trade.mqh>

//--- Parâmetros de entrada
input double stopLoss=100; // Stop loss
input double Lots=1.0; // Lots
input int    magicNumber=989898; // Número mágico EA
input int    horaAberturaMercado=0; // Hora de abertura do mercado
input int    horaFechamentoMercado=0; // Hora de fechamento do mercado
input int    posicoesAbertas=10; // Máximo de posições abertas
input double prejuizoMaximo=10.0; // Prejuízo máximo de uma posição aberta
input double lucroMaximo=10.0; // Lucro máximo de uma posição aberta
input bool  eMiniIndiceBMF=true; // Trabalhando com minicontrato?

//--- Variáveis estáticas
static int spread=10;

//--- Classes
CTrade cTrade; // Classe com métodos para negociação

//--- Handle dos indicadores
int maCurtaHandle,maLongaHandle;

//--- Buffers
double maCurtaBuffer[],maLongaBuffer[];
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

// Obtém a hora atual
   MqlDateTime horaAtual;
   TimeCurrent(horaAtual);

   if(isNewBar() && marketOpened(horaAtual))
     {

      //--- Obtém o valor do spread
      spread=(int)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);

      //--- Obtém as informações do último preço da cotação
      MqlTick ultimoPreco;
      if(!SymbolInfoTick(_Symbol,ultimoPreco))
        {
         Print("Erro ao obter a última cotação - error ",GetLastError());
         return;
        }

      //--- Verifica as posições abertas
      for(int i=PositionsTotal()-1; i>=0; i--)
        {
         if(PositionSelectByTicket(PositionGetTicket(i))
            && ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE))==POSITION_TYPE_BUY)
           {

            Print("Ticket da posição: ",PositionGetTicket(i));
            Print("Último Preço ask: ", ultimoPreco.ask);
            Print("Último Preço bid: ", ultimoPreco.bid);
            Print("Stop loss da posição: ",NormalizeDouble(PositionGetDouble(POSITION_SL),_Digits));
            Print("Lucro da posição: ",PositionGetDouble(POSITION_PROFIT));
            Print("Valor MA curta: ",NormalizeDouble(maCurtaBuffer[1],_Digits));
            Print("Valor MA longa: ",NormalizeDouble(maLongaBuffer[1],_Digits));

            //--- Determina se estamos em uma tendência de alta
            double mediaMovel=0;
            if(maCurtaBuffer[1]>maLongaBuffer[1] && maCurtaBuffer[1] < PositionGetDouble(POSITION_SL)) 
              {
               mediaMovel=NormalizeDouble(maCurtaBuffer[1],_Digits);

               // Realiza o trailiing stop da posição
               MarketOrder(ORDER_TYPE_BUY,
                           TRADE_ACTION_SLTP,
                           PositionGetDouble(POSITION_PRICE_OPEN),
                           PositionGetDouble(POSITION_VOLUME),
                           arredondaMediaMovel(mediaMovel),
                           PositionGetDouble(POSITION_TP),
                           100,
                           PositionGetTicket(i));
              }

              } else {

            Print("Ticket da posição: ",PositionGetTicket(i));
            Print("Último Preço ask: ", ultimoPreco.ask);
            Print("Último Preço bid: ", ultimoPreco.bid);
            Print("Stop loss da posição: ",NormalizeDouble(PositionGetDouble(POSITION_SL),_Digits));
            Print("Lucro da posição: ",PositionGetDouble(POSITION_PROFIT));
            Print("Valor MA curta: ",NormalizeDouble(maCurtaBuffer[1],_Digits));
            Print("Valor MA longa: ",NormalizeDouble(maLongaBuffer[1],_Digits));

            //--- Determina se estamos em uma tendência de alta
            double mediaMovel=0;
            if(maCurtaBuffer[1]<maLongaBuffer[1] && maCurtaBuffer[1] > PositionGetDouble(POSITION_SL)) 
              {
               mediaMovel=NormalizeDouble(maCurtaBuffer[1],_Digits);

               // Realiza o trailiing stop da posição
               MarketOrder(ORDER_TYPE_BUY,
                           TRADE_ACTION_SLTP,
                           PositionGetDouble(POSITION_PRICE_OPEN),
                           PositionGetDouble(POSITION_VOLUME),
                           arredondaMediaMovel(mediaMovel),
                           PositionGetDouble(POSITION_TP),
                           100,
                           PositionGetTicket(i));
              }

           }
        }

      //--- Armazena a quantidade de posições abertas
      //--- Caso a conta seja hegding, obtém a informação de PositionsTotal()
      //--- Caso a conta seja netting, obtém o volume da posição aberta
      int totalPosicoes=PositionsTotal();
      if(((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE))==ACCOUNT_MARGIN_MODE_RETAIL_NETTING)
        {
         if(totalPosicoes>0 && PositionSelectByTicket(PositionGetTicket(0)))
           {
            totalPosicoes=(int)PositionGetDouble(POSITION_VOLUME);
           }
        }

      //--- Obtém o valor do sinal de negociação
      double sinalNegociacaoValue=sinalNegociacao();

      //--- Verifica a possibilidade de abrir posições longas e curtas
      //--- Só abre uma nova posição se não tiver extrapolado o limite estabelecido
      if(totalPosicoes<posicoesAbertas)
        {
         if(sinalNegociacaoValue>0)
           {
            MarketOrder(ORDER_TYPE_BUY,
                        TRADE_ACTION_DEAL,
                        ultimoPreco.ask,
                        Lots,
                        ultimoPreco.ask-stopLoss*_Point,
                        0);
              } else if(sinalNegociacaoValue<0) {
            MarketOrder(ORDER_TYPE_SELL,
                        TRADE_ACTION_DEAL,
                        ultimoPreco.bid,
                        Lots,
                        ultimoPreco.bid+stopLoss*_Point,
                        0);
           }
        }

     }

  }
//+------------------------------------------------------------------+ 
//|  Retorna true caso esteja dentro do perído permitido pelo        |
//|  usuário e a corretora para efetuar operações daytrade.          |
//+------------------------------------------------------------------+  
bool marketOpened(MqlDateTime &hora)
  {

//--- Caso o valor do horário de abertura e fechamento seja zero(0), 
//--- não tem hora de restrição para operar no mercado
   if(horaAberturaMercado==0 && horaFechamentoMercado==0)
     {
      return(true);
     }

//--- Verifica se o horário atual permite operar
   if(hora.hour>=horaAberturaMercado && hora.hour<horaFechamentoMercado)
     {
      return(true);
        } else {
      //--- Fecha as posições abertas caso exista
      fecharPosicoesAbertas(POSITION_TYPE_BUY);
      fecharPosicoesAbertas(POSITION_TYPE_SELL);
     }

   return(false);
  }
//+------------------------------------------------------------------+ 
//|  Fecha todas as posições que estão atualmente abertas            |
//+------------------------------------------------------------------+  
void fecharPosicoesAbertas(ENUM_POSITION_TYPE typeOrder)
  {

/* Fecha a posição anteriormente abertas */
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      // Verifica se a posição aberta é uma posição inversa
      if(PositionSelectByTicket(PositionGetTicket(i)) && ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE))==typeOrder)
        {
         cTrade.PositionClose(PositionGetTicket(i));
        }
     }
  }
//+------------------------------------------------------------------+ 
//|  Efetua uma operação de negociação a mercado                     |
//|  Função obtida no seguinte tópico de ajuda:                      |
//|  https://www.mql5.com/pt/docs/event_handlers/ontick              |
//+------------------------------------------------------------------+
bool MarketOrder(ENUM_ORDER_TYPE typeOrder,
                 ENUM_TRADE_REQUEST_ACTIONS typeAction,
                 double price,
                 double volume,
                 double stop,
                 double profit,
                 ulong deviation=100,
                 ulong positionTicket=0)
  {

//--- Declaração e inicialização das estruturas
   MqlTradeRequest tradeRequest; // Envia as requisições de negociação
   MqlTradeResult tradeResult; // Receba o resultado das requisições de negociação
   ZeroMemory(tradeRequest); // Inicializa a estrutura
   ZeroMemory(tradeResult); // Inicializa a estrutura

//--- Popula os campos da estrutura tradeRequest
   tradeRequest.action=typeAction; // Tipo de execução da ordem
   tradeRequest.price=NormalizeDouble(price,_Digits); // Preço da ordem
   tradeRequest.sl=NormalizeDouble(stop,_Digits); // Stop loss da ordem
   tradeRequest.tp=NormalizeDouble(profit,_Digits); // Take profit da ordem
   tradeRequest.symbol= _Symbol; // Símbolo
   tradeRequest.volume = volume; // Volume a ser negociado
   tradeRequest.type= typeOrder; // Tipo de ordem
   tradeRequest.magic=magicNumber; // Número mágico do EA
   tradeRequest.type_filling=ORDER_FILLING_FOK; // Tipo de execução da ordem
   tradeRequest.deviation=deviation; // Desvio permitido em relação ao preço
   tradeRequest.position=positionTicket; // Ticket da posição

//--- Envia a ordem
   if(!OrderSend(tradeRequest,tradeResult))
     {
      //-- Exibimos as informações sobre a falha
      Alert("Não foi possível enviar a ordem. Erro ",GetLastError());
      PrintFormat("Envio de ordem %s %s %.2f a %.5f, erro %d",tradeRequest.symbol,EnumToString(typeOrder),volume,tradeRequest.price,GetLastError());
      return(false);
     }

//-- Exibimos as informações sobre a ordem bem-sucedida
   Alert("Uma nova ordem foi enviada com sucesso! Ticket #", tradeResult.order);
   PrintFormat("Código %u, negociação %I64u, ticket #%I64u", tradeResult.retcode, tradeResult.deal, tradeResult.order);
   return(true);
  }
//+------------------------------------------------------------------+ 
//|  Retorna true quando aparece uma nova barra                      |
//|  Função obtida no seguinte tópico de ajuda:                      |
//|  https://www.mql5.com/pt/docs/event_handlers/ontick              |
//+------------------------------------------------------------------+ 
bool isNewBar()
  {

   static datetime barTime=0; // Armazenamos o tempo de abertura da barra atual
   datetime currentBarTime=iTime(_Symbol,_Period,0); // Obtemos o tempo de abertura da barra zero

                                                     //-- Se o tempo de abertura mudar, é porque apareceu uma nova barra
   if(barTime!=currentBarTime)
     {
      barTime=currentBarTime;
      return(true); // temos uma nova barra
     }

   return(false); // não há nenhuma barra nova
  }
//+------------------------------------------------------------------+
//|  Realiza o arredondamento para múltiplo de 5 quando se opera     |
//|  com minicontrato de índice.                                     |
//+------------------------------------------------------------------+ 
double arredondaMediaMovel(double mediaMovel) 
  {

   double resultado=mediaMovel;
   if(eMiniIndiceBMF) 
     {
      if(fmod(mediaMovel,5)==0) 
        {
         // Não precisa arredondar para 5
         return(resultado);
           } else {
         // Diminui o resto da divisão da média móvel para igualar ao
         // último múltiplo de 5
         resultado=mediaMovel-fmod(mediaMovel,5);
        }
     }

   return(resultado);
  }
//+------------------------------------------------------------------+
//|  Função responsável por informar se o momento é de abrir uma     |
//|  posição de compra ou venda.                                     |
//|                                                                  |
//|  -1 - Abre uma posição de venda                                  |
//|  +1 - Abre uma posição de compra                                 |
//|   0 - Nenhum posição é aberta                                    |
//+------------------------------------------------------------------+
double sinalNegociacao()
  {

//--- Zero significa que não é pra abrir nenhum posição
   int sinal=0;

//--- Instanciação dos indicadores
   maCurtaHandle = iMA(_Symbol, _Period, 8, 0, MODE_EMA, PRICE_CLOSE);
   maLongaHandle = iMA(_Symbol, _Period, 20, 0, MODE_SMA, PRICE_CLOSE);

   if(maCurtaHandle<0 || maLongaHandle<0)
     {
      Alert("Erro ao criar os indicadores - erro: ",GetLastError(),"!!!");
      return(sinal);
     }

//--- Copia o valor do indicador para o array
   if(CopyBuffer(maCurtaHandle,0,0,3,maCurtaBuffer)<3)
     {
      Print("Falha ao copiar dados do indicador MA curta! Erro: ",GetLastError());
      return(sinal);
     }

// Define o array como uma série temporal
   if(!ArraySetAsSeries(maCurtaBuffer,true))
     {
      Print("Falha ao definir o buffer MA curta como série temporal! Erro: ",GetLastError());
      return(sinal);
     }

//--- Copia o valor do indicador para o array
   if(CopyBuffer(maLongaHandle,0,0,2,maLongaBuffer)<2)
     {
      Print("Falha ao copiar dados do indicador MA longa! Erro: ",GetLastError());
      return(sinal);
     }

// Define o array como uma série temporal
   if(!ArraySetAsSeries(maLongaBuffer,true))
     {
      Print("Falha ao definir o buffer MA longa como série temporal! Erro: ",GetLastError());
      return(sinal);
     }

//--- Checa a condição e seta o valor para o sinal
   if(maCurtaBuffer[2]<maLongaBuffer[1] && maCurtaBuffer[1]>maLongaBuffer[1])
     {
      sinal=1;
        } else if(maCurtaBuffer[2]>maLongaBuffer[1] && maCurtaBuffer[1]<maLongaBuffer[1]) {
      sinal=-1;
        } else {
      sinal=0;
     }

//--- Retorna o sinal de negociação
   return(sinal);
  }
//+------------------------------------------------------------------+
