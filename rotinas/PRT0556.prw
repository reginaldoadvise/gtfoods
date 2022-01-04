#Include "TOTVS.ch"

/*/{Protheus.doc} PRT0556
Rotina de cadastro da TES para o Atua
@author Tiago Malta
@since 15/04/2019
@type function
/*/
User Function PRT0556()

    AXCADASTRO("UQA","Regras TES", /*"VLDDEL()"*/, /*"VLDALT"*/, /*aRotAdic*/, /*bPre*/, { || U_VLDP554() } /*bOK*/, /*bTTS*/, /*bNoTTS*/, , , /*aButtons*/, , )  

Return

User Function VLDP554()    

Local lRet := .T.

    If Inclui
        DbSelectArea("UQA")
        UQA->( dbsetorder(1) )
        If UQA->(DbSeek(xFilial("UQA")  + M->UQA_EMPEMI + M->UQA_UFORIG + M->UQA_UFDEST + M->UQA_CFOP + M->UQA_CSTICM + M->UQA_CSTPIS + M->UQA_CSTCOF ))
            MsgStop("Regra de TES existente com estas configurações.") 
            lRet := .F.
        EndIf
    Endif

Return lRet
