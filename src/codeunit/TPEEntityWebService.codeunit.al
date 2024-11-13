codeunit 60000 "TPE Entity Web Service"
{
    var
        EntityManagement: Codeunit "TPE Entity Management";

    procedure GetEntities() Result: Text
    begin
        this.EntityManagement.GetEntities().WriteTo(Result);
    end;

    procedure EntityData(pEntityCode: Code[20]; pView: Text; pPageIndex: Integer; pFilterParams: Text; pRelatedEntityCode: Code[20]) Result: Text
    begin
        this.EntityManagement.GetEntityData(pEntityCode, pView, pPageIndex, pFilterParams, pRelatedEntityCode).WriteTo(Result);
    end;

    procedure EntityAmend(pEntityCode: code[20]; pAmendType: Text; pRecord: Text)
    begin
        this.EntityManagement.WriteData(pEntityCode, pAmendType, pRecord);
    end;

    procedure EntityDataSearch(pEntityCode: code[20]; pSearchTerm: Text) Result: Text
    begin
        //this.EntityManagement.SearchRelatedTableRecord(pEntityCode, pSearchTerm).writeTo(Result);
    end;
}