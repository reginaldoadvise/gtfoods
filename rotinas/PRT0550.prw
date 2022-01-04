#Include "Totvs.ch"

Static NomePrt      := "PRT0550"
Static VersaoJedi   := "V1.01"

/*/{Protheus.doc} PRT0550
Cadastro de moedas Arquivo X Protheus.
@author Paulo Carvalho
@since 21/03/2019
@type function
/*/
User Function PRT0550()

    Local oBrowse       := Nil

    Private aRotina     := MenuDef()

    Private cCadastro   := NomePrt + " - " + Alltrim(Posicione("SX2",1,"UQN","X2Nome()")) + " - " + VersaoJedi

    //Inst�nciando FWMBrowse - Somente com dicion�rio de dados
    oBrowse := FWMBrowse():New()

    //Setando a tabela de cadastro
    oBrowse:SetAlias("UQN")

    //Setando a descri��o da rotina
    oBrowse:SetDescription(cCadastro)

    //Ativa a Browse
    oBrowse:Activate()

Return(Nil)

/*/{Protheus.doc} ModelDef
Defini��o de Modelo MVC
@author Paulo Carvalho
@since 21/03/2019
@type function
/*/
Static Function ModelDef()

    Local oModel    := Nil //Cria��o do objeto do modelo de dados
    Local oStUQN    := FWFormStruct(1, "UQN") //Cria��o da estrutura de dados utilizada na interface

    //Instanciando o modelo
    oModel := MPFormModel():New("MVCUQN",/* bPre */, /* bPos */,/*bCommit*/,/*bCancel*/)

    //Atribuindo formul�rios para o modelo
    oModel:AddFields("FORMUQN",/*cOwner*/,oStUQN)

    //Setando a chave prim�ria da rotina
    oModel:SetPrimaryKey({"UQN_MOEDAR","UQN_CODIGO"})

    //Adicionando descri��o ao modelo
    oModel:SetDescription( cCadastro )

    //Setando a descri��o do formul�rio
    oModel:GetModel("FORMUQN"):SetDescription( cCadastro )

Return(oModel)

/*/{Protheus.doc} ViewDef
Defini��o do View
@author Paulo Carvalho
@since 21/03/2019
@type function
@return oView, Objeto do View
/*/
Static Function ViewDef()

    Local oModel    := ModelDef()  //Cria��o do objeto do modelo de dados
    Local oStUQN    := FWFormStruct(2, "UQN") //Cria��o da estrutura de dados
    Local oView     := Nil //Criando oView como nulo

    //Criando a view que ser� o retorno da fun��o e setando o modelo da rotina
    oView := FWFormView():New()
    oView:SetModel(oModel)

    //Atribuindo formul�rios para interface
    oView:AddField("V_UQN", oStUQN, "FORMUQN")

    //Criando um container com nome tela com 100%
    oView:CreateHorizontalBox("TELA",100)

    //Colocando t�tulo do formul�rio
    oView:EnableTitleView("V_UQN", cCadastro)

    //For�a o fechamento da janela na confirma��o
    oView:SetCloseOnOk({|| .T.})

    //O formul�rio da interface ser� colocado dentro do container
    oView:SetOwnerView("V_UQN","TELA")

Return(oView)

/*/{Protheus.doc} MenuDef
Defini��o de MenuDef
@author Paulo Carvalho
@since 21/03/2019
@type function
@return aRotina, Array com Fun��o dos Bot�es
/*/
Static Function MenuDef()
Return(FWMVCMenu("PRT0550"))
