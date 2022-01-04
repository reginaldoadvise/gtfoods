#include "Protheus.ch"
#include "totvs.ch"
/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �fAltSE4Adt�Autor  �Reginaldo G Ribeiro � Data �  23/09/21   ���
�������������������������������������������������������������������������͹��
���Desc.     �  EM QUE PONTO : Ao acessar uma das opcoes da 
                NFE (2=Visualiza/ 3=Incluir/ 4=Classificar/ 5=Excluir)
                Identificar atraves do parametro enviado.
�������������������������������������������������������������������������͹��
���Uso       �                               ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
User Function fAltSE4Adt()
Local cGLPcpadt := "__XVaraDT"
Local cGLPAlt   := "__xAltAdt"
Local cctrAdt   := GetGlbValue(cGLPcpadt)
Local cAltAdt   := GetGlbValue(cGLPAlt)
Local aPedAdto  := {}
Local aPedidos  := {}

    If Empty(cAltAdt) .or. cAltAdt=='2' 
        ClearGlbValue(cGLPAlt)
        PutGlbValue( cGLPcpadt , "2" )
        aAdd(aPedAdto,SD1->D1_PEDIDO)
        aPedidos := FPedAdtPed("P", aPedAdto, .F. )
        If Len(aPedidos)>0
            dbselectArea("SE4")
            SE4->(DBSETORDER(1))
            If SE4->(DBSEEK(XFILIAL("SE4")+CCONDICAO))
                If SE4->E4_CTRADT<>'1'
                    ClearGlbValue(cGLPcpadt)
                    PutGlbValue( cGLPcpadt , SE4->E4_CTRADT )//__XVaraDT:= SE4->E4_CTRADT
                    ClearGlbValue(cGLPAlt)
                    PutGlbValue( cGLPAlt , "1" )
                    RecLock("SE4", .F.)
                        SE4->E4_CTRADT:= "1"
                    MsUnlock()
                EndIf    
            EndIf
        EndIf
    ElseIf cAltAdt=="1"
        dbselectArea("SE4")
        SE4->(DBSETORDER(1))
        If SE4->(DBSEEK(XFILIAL("SE4")+CCONDICAO))     
            RecLock("SE4", .F.)
            SE4->E4_CTRADT:= GetGlbValue(cGLPcpadt)
            MsUnlock()
            ClearGlbValue(cGLPAlt)
        EndIf    
    EndIf
RETURN
