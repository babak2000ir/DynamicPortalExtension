codeunit 60000 "TPE Entity Web Service"
{
    var
        EntityManagement: Codeunit "TPE Entity Management";

    procedure GetEntities() Result: Text
    begin
        this.EntityManagement.GetEntities().WriteTo(Result);
    end;

    procedure GetEntityRecords(pEntityCode: Code[20]; pView: Text; pPageSize: integer; pPageIndex: Integer) Result: Text
    begin
        this.EntityManagement.GetEntityRecords(pEntityCode, pView, pPageSize, pPageIndex).WriteTo(Result);
    end;

    procedure GetEntityRecord(pEntityCode: Code[20]; pKeyFieldsView: Text) Result: Text
    begin
        this.EntityManagement.GetEntityRecord(pEntityCode, pKeyFieldsView).WriteTo(Result);
    end;

    procedure EntityAmend(pEntityCode: code[20]; pAmendType: Text; pRecord: Text)
    begin
        this.EntityManagement.WriteData(pEntityCode, pAmendType, pRecord);
    end;
}