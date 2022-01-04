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

    //Instânciando FWMBrowse - Somente com dicionário de dados
    oBrowse := FWMBrowse():New()

    //Setando a tabela de cadastro
    oBrowse:SetAlias("UQN")

    //Setando a descrição da rotina
    oBrowse:SetDescription(cCadastro)

    //Ativa a Browse
    oBrowse:Activate()

Return(Nil)

/*/{Protheus.doc} ModelDef
Definição de Modelo MVC
@author Paulo Carvalho
@since 21/03/2019
@type function
/*/
Static Function ModelDef()

    Local oModel    := Nil //Criação do objeto do modelo de dados
    Local oStUQN    := FWFormStruct(1, "UQN") //Criação da estrutura de dados utilizada na interface

    //Instanciando o modelo
    oModel := MPFormModel():New("MVCUQN",/* bPre */, /* bPos */,/*bCommit*/,/*bCancel*/)

    //Atribuindo formulários para o modelo
    oModel:AddFields("FORMUQN",/*cOwner*/,oStUQN)

    //Setando a chave primária da rotina
    oModel:SetPrimaryKey({"UQN_MOEDAR","UQN_CODIGO"})

    //Adicionando descrição ao modelo
    oModel:SetDescription( cCadastro )

    //Setando a descrição do formulário
    oModel:GetModel("FORMUQN"):SetDescription( cCadastro )

Return(oModel)

/*/{Protheus.doc} ViewDef
Definição do View
@author Paulo Carvalho
@since 21/03/2019
@type function
@return oView, Objeto do View
/*/
Static Function ViewDef()

    Local oModel    := ModelDef()  //Criação do objeto do modelo de dados
    Local oStUQN    := FWFormStruct(2, "UQN") //Criação da estrutura de dados
    Local oView     := Nil //Criando oView como nulo

    //Criando a view que será o retorno da função e setando o modelo da rotina
    oView := FWFormView():New()
    oView:SetModel(oModel)

    //Atribuindo formulários para interface
    oView:AddField("V_UQN", oStUQN, "FORMUQN")

    //Criando um container com nome tela com 100%
    oView:CreateHorizontalBox("TELA",100)

    //Colocando título do formulário
    oView:EnableTitleView("V_UQN", cCadastro)

    //Força o fechamento da janela na confirmação
    oView:SetCloseOnOk({|| .T.})

    //O formulário da interface será colocado dentro do container
    oView:SetOwnerView("V_UQN","TELA")

Return(oView)

/*/{Protheus.doc} MenuDef
Definição de MenuDef
@author Paulo Carvalho
@since 21/03/2019
@type function
@return aRotina, Array com Função dos Botões
/*/
Static Function MenuDef()
Return(FWMVCMenu("PRT0550"))
