codeunit 60000 "TNP Entity Web Service"
{

    var
        EntityMgmt: Codeunit "TPE Entity Management";
        PortalUserMgmt: Codeunit "TPE Portal User Management";
        TechnicalOptionTxt: TextConst ENU = '%1';
        UserNotFoundSecureErr: Label 'Invalid credentials. The password is incorrect or no registered user was found for the provided user email.';
    #Region Interface
    procedure Tables(pTableFilter: Text; WithFields: Boolean): Text
    var
        lResult: Text;
    begin
        GetTables(pTableFilter, WithFields).WriteTo(lResult);
        exit(lResult);
    end;

    procedure Entities(EntityCode: Code[20]; WithFields: Boolean): Text
    var
        lResult: Text;
    begin
        GetEntities(EntityCode, WithFields).WriteTo(lResult);
        exit(lResult);
    end;

    procedure EntityData(pEntityCode: Code[20]; pView: Text; pPageIndex: Integer; pFilterParams: Text; pRelatedEntityCode: Code[20]): Text
    var
        lEntity: Record "TNP Entity Header";
    begin
        if lEntity.Get(pEntityCode) then
            exit(EntityData(lEntity."Table ID", pEntityCode, pView, pPageIndex, pFilterParams, pRelatedEntityCode));
    end;

    procedure TableData(pTableNo: Integer; pView: Text; pPageIndex: Integer; pFilterParams: Text; pRelatedEntityCode: Code[20]): Text
    begin
        exit(EntityData(pTableNo, '', pView, pPageIndex, pFilterParams, pRelatedEntityCode));
    end;

    procedure EntityDataAmend(pEntityCode: code[20]; pAmendType: Text; pRecord: Text; pIDFilterString: Text): Text
    var
        lEntity: Record "TNP Entity Header";
    begin
        if lEntity.Get(pEntityCode) then
            this.WriteData(lEntity."Table ID", lEntity, pAmendType, pRecord, pIDFilterString);
        exit(this.EntityDataAmendLocal(pAmendType));
    end;

    procedure TableDataAmend(pTableNo: Integer; pAmendType: Text; pRecord: Text; pIDFilterString: Text): Text
    var
        lEntity: Record "TNP Entity Header";
    begin
        lEntity."Insert Allowed" := true;
        lEntity."Modify Allowed" := true;
        lEntity."Delete Allowed" := true;
        WriteData(pTableNo, lEntity, pAmendType, pRecord, pIDFilterString);
        exit(EntityDataAmendLocal(pAmendType));
    end;

    procedure TableDataSearch(pTableNo: Integer; pSearchTerm: Text): Text
    begin
        exit(searchRelatedTableRecord(pTableNo, pSearchTerm));
    end;

    procedure EntityDataSearch(pEntityCode: code[20]; pSearchTerm: Text): Text
    var
        lEntity: Record "TNP Entity Header";
    begin
        if lEntity.Get(pEntityCode) then
            exit(searchRelatedTableRecord(lEntity."Table ID", pSearchTerm));
    end;

    local procedure EntityDataAmendLocal(pAmendType: Text): Text
    var
        lJOData: JsonObject;
        lJResult: Text;
    begin
        case pAmendType of
            'Insert':
                lJOData.add('message', 'Record inserted successfully');
            'Modify':
                lJOData.add('message', 'Record modified successfully');
            'Delete':
                lJOData.add('message', 'Record deleted successfully');
        end;
        lJOData.WriteTo(lJResult);
        exit(lJResult);
    end;

    procedure WriteEntityData(pEntityCode: Code[20]; Activity: Text; pFieldValueArray: text)
    var
        lEntity: Record "TNP Entity Header";
    begin
        if lEntity.Get(pEntityCode) then
            WriteData(lEntity."Table ID", lEntity, Activity, pFieldValueArray, '');
    end;

    procedure WriteTableData(pTableNo: Integer; Activity: Text; pFieldValueArray: text)
    var
        lEntityDummy: Record "TNP Entity Header";
    begin
        WriteData(pTableNo, lEntityDummy, Activity, pFieldValueArray, '');
    end;
    #endregion Interface

    #Region Json Methods
    local procedure GetEntities(EntityCode: Code[20]; WithFields: Boolean): JsonObject
    var
        Entities: Record "TNP Entity Header";
        lJAEntities: JsonArray;
        lJOEntity: JsonObject;
        lJOResult: JsonObject;
    begin
        Entities.Reset();
        if EntityCode <> '' then
            Entities.SetFilter("Entity Code", EntityCode);

        Entities.SetAutoCalcFields("Table Name");

        if Entities.FindSet(false) then
            repeat
                Clear(lJOEntity);

                GetTable(Entities."Entity Code", Entities."Table ID", Entities."Table Name", Entities."Entity Name", Entities."Insert Allowed", Entities."Modify Allowed", Entities."Delete Allowed", WithFields, lJOEntity);

                lJOEntity.Add('relations', GetTableRelations(Entities."Entity Code", WithFields));

                lJAEntities.Add(lJOEntity);

            until Entities.Next() = 0;

        lJOResult.Add('entities', lJAEntities);
        exit(lJOResult);
    end;

    local procedure GetTables(pTableIdFilter: Text; WithFields: Boolean): JsonObject
    var
        lAllObjWithCaption: Record AllObjWithCaption;
        lJATables: JsonArray;
        lJOTable: JsonObject;
        lJOResult: JsonObject;
    begin
        lAllObjWithCaption.Reset();
        //if pTableIdFilter <> '' then
        //    lAllObjWithCaption.SetFilter("Object ID", pTableIdFilter + '&<2000000000')
        //else
        //    lAllObjWithCaption.SetFilter("Object ID", '<%1', 2000000001);
        lAllObjWithCaption.SetRange("Object Type", lAllObjWithCaption."Object Type"::Table);
        lAllObjWithCaption.SetRange("Object Subtype", 'Normal');
        lAllObjWithCaption.FindSet();
        repeat
            Clear(lJOTable);

            GetTable('', lAllObjWithCaption."Object ID", lAllObjWithCaption."Object Name", lAllObjWithCaption."Object Caption", true, true, true, WithFields, lJOTable);

            lJATables.Add(lJOTable);
        until lAllObjWithCaption.Next() = 0;

        lJOResult.Add('tables', lJATables);
        exit(lJOResult);
    end;

    local procedure GetTable(pEntityCode: Code[20]; TableId: Integer; TableName: Text; Caption: Text; InsertAllowed: Boolean; ModifyAllowed: Boolean; DeleteAllowed: Boolean; WithFields: Boolean; var pJOTable: JsonObject)
    begin
        pJOTable.Add('id', TableId);
        pJOTable.Add('name', TableName);
        pJOTable.Add('entityCode', pEntityCode);
        pJOTable.Add('caption', Caption);
        pJOTable.Add('insertAllowed', InsertAllowed);
        pJOTable.Add('modifyAllowed', ModifyAllowed);
        pJOTable.Add('deleteAllowed', DeleteAllowed);

        if WithFields then
            pJOTable.Add('fields', GetTableFields(TableId, pEntityCode));
    end;

    local procedure GetTableRelations(pEntityCode: Code[20]; WithFields: Boolean): JsonArray
    var
        lEntityRelationTable: Record "TNP Entity Related Table";
        lEntity: Record "TNP Entity Header";
        lEntityRelationFilter: record "TNP Ent. Rel. Table Filter";
        pJOTable: JsonObject;
        pJATables: JsonArray;
        lJOEntityRelations: JsonObject;
        lJAEntityRelations: JsonArray;
    begin
        lEntityRelationTable.Reset();
        lEntityRelationTable.SetFilter("Entity Code", pEntityCode);
        lEntityRelationTable.SetAutoCalcFields("Related Table Name");
        if lEntityRelationTable.FindSet() then
            repeat
                Clear(pJOTable);
                if (lEntityRelationTable."Related Entity" <> '') and lEntity.Get(lEntityRelationTable."Related Entity") then
                    GetTable(lEntityRelationTable."Related Entity",
                        lEntityRelationTable."Related Table ID", lEntityRelationTable."Related Table Name", lEntity."Entity Name",
                        lEntity."Insert Allowed", lEntity."Modify Allowed", lEntity."Delete Allowed",
                        WithFields, pJOTable)
                else
                    GetTable('',
                        lEntityRelationTable."Related Table ID", lEntityRelationTable."Related Table Name", lEntityRelationTable."Related Table Name",
                        true, true, true,
                        WithFields, pJOTable);

                Clear(lJAEntityRelations);
                lEntityRelationFilter.Reset();
                lEntityRelationFilter.SetRange("Entity Code", pEntityCode);
                lEntityRelationFilter.SetRange("Related Table ID", lEntityRelationTable."Related Table ID");
                if lEntityRelationFilter.FindSet() then
                    repeat
                        clear(lJOEntityRelations);

                        lJOEntityRelations.Add('entityFieldId', lEntityRelationFilter."Entity Header Field ID");
                        lJOEntityRelations.Add('fieldRelation', StrSubstNo(TechnicalOptionTxt, lEntityRelationFilter."Field Relation"));
                        lJOEntityRelations.Add('relationFieldId', lEntityRelationFilter."Related Table Field ID");

                        lJAEntityRelations.Add(lJOEntityRelations);
                    until lEntityRelationFilter.Next() = 0;

                pJOTable.Add('relationFilters', lJAEntityRelations);
                pJATables.Add(pJOTable);
            until lEntityRelationTable.Next() = 0;

        exit(pJATables);
    end;

    local procedure GetTableFields(pTableNo: Integer): JsonArray
    begin
        exit(GetTableFields(pTableNo, ''));
    end;

    local procedure GetTableFields(pTableNo: Integer; EntityCode: Code[20]): JsonArray
    var
        lField: Record Field;
        TempEntityFields: Record "TNP Entity Field" temporary;
        lJAFields: JsonArray;
        lFieldFilter: Text;
    begin
        lFieldFilter := '';
        lField.Reset();

        if EntityCode <> '' then begin
            //get table keys
            this.EntityMgmt.GetFieldFilter(pTableNo, EntityCode, lFieldFilter, TempEntityFields);
            lField.SetFilter("No.", lFieldFilter);
        end;
        lField.SetRange(TableNo, pTableNo);
        lField.SetRange(Enabled, true);
        lField.SetRange(ObsoleteState, lField.ObsoleteState::No);
        if lField.FindSet() then
            repeat
                lJAFields.Add(GetEntityFieldInfo(lField, EntityCode));
            until lField.Next() = 0;

        exit(lJAFields);
    end;

    local procedure GetEntityFieldInfo(pField: Record Field; pEntityCode: Code[20]): JsonObject
    var
        pEntityFields: Record "TNP Entity Field";
        lJOField: JsonObject;
    begin
        lJOField.Add('id', pField."No.");
        lJOField.Add('name', pField.FieldName);
        lJOField.Add('caption', pField."Field Caption");
        lJOField.Add('type', StrSubstNo(TechnicalOptionTxt, pField.Type));
        lJOField.Add('length', pField.Len);
        lJOField.Add('class', StrSubstNo(TechnicalOptionTxt, pField.Class));

        if pField.Type = pField.Type::Option then
            lJOField.Add('optionMembers', pField.OptionString);

        if pField.RelationTableNo <> 0 then begin
            lJOField.Add('relationTableNo', pField.RelationTableNo);
            lJOField.Add('relationFieldNo', pField.RelationFieldNo);
        end;

        if pField.IsPartOfPrimaryKey then
            lJOField.Add('partOfPrimaryKey', true);

        pEntityFields.Reset();

        pEntityFields.SetRange("Field ID", pField."No.");
        pEntityFields.SetRange("Entity Code", pEntityCode);
        pEntityFields.SetRange("Read Only", true);

        if pEntityFields.FindFirst() then
            lJOField.Add('readOnly', pEntityFields."Read Only")
        else
            lJOField.Add('readOnly', false);

        exit(lJOField);
    end;

    local procedure EntityData(pTableNo: Integer; pEntityCode: Code[20]; pView: Text; pPageIndex: Integer; pFilterParams: Text; pRelatedEntityCode: Code[20]): Text
    var
        lResult: Text;
    begin
        GetEntityData(pTableNo, pEntityCode, pView, pPageIndex, pFilterParams, pRelatedEntityCode).WriteTo(lResult);
        exit(lResult);
    end;

    local procedure GetEntityData(pTableNo: Integer; pEntityCode: Code[20]; pView: Text; pPageIndex: Integer; pFilterParams: Text; pRelatedEntityCode: Code[20]): JsonObject
    var
        lPageCount: Integer;
        lJARecords: JsonArray;
        lJAPaging, lJOData : JsonObject;
        lJOResult: JsonObject;
    begin
        GetEntityRecords(pTableNo, pEntityCode, pView, lJARecords, pPageIndex, lPageCount, pFilterParams, pRelatedEntityCode);

        lJAPaging.Add('pageIndex', pPageIndex);
        lJAPaging.Add('pageCount', lPageCount);

        lJOData.Add('paging', lJAPaging);
        lJOData.Add('records', lJARecords);

        lJOResult.Add('data', lJOData);
        exit(lJOResult);
    end;

    local procedure GetEntityRecords(pTableNo: Integer; pEntityCode: Code[20]; pView: Text; var pJARecords: JsonArray; pPageIndex: Integer; var pPageCount: Integer; pFilterParams: Text; pRelatedEntityCode: Code[20])
    var
        lEntityRelationFilter: record "TNP Ent. Rel. Table Filter";
        lRecordRef: RecordRef;
        lFieldRef: FieldRef;
        lintCounter: Integer;
        lPageSize: Integer;
        valueQuery: Text;
        lJTFieldValue: JsonToken;
        lJFilterValue: JsonArray;
    begin
        lPageSize := 10;

        Clear(pJARecords);
        lRecordRef.Open(pTableNo);

        if pView <> '' then
            lRecordRef.SetView(pView);

        // Filter BY RelationFilter Field ID
        lJFilterValue.ReadFrom(pFilterParams);
        if lJFilterValue.Count > 0 then begin
            lEntityRelationFilter.Reset();
            lEntityRelationFilter.SetRange("Entity Code", pRelatedEntityCode);
            lEntityRelationFilter.SetRange("Related Table ID", pTableNo);
            if lEntityRelationFilter.FindSet() then
                repeat
                    lFieldRef := lRecordRef.Field(lEntityRelationFilter."Related Table Field ID");
                    valueQuery := '[?(@.id==''' + Format(lEntityRelationFilter."Related Table Field ID") + ''')].value';
                    lJFilterValue.SelectToken(valueQuery, lJTFieldValue);
                    lFieldRef.SetFilter(lJTFieldValue.AsValue().AsText());
                until lEntityRelationFilter.Next() = 0;
        end;

        pPageCount := (lrecordRef.Count() div lPageSize) + 1;

        lintCounter := 1;
        lRecordRef.FindSet();
        if pPageIndex > 1 then
            if lRecordRef.next((pPageIndex - 1) * lPageSize) <> 0 then
                repeat
                    pJARecords.Add(GetEntityFieldValues(pTableNo, pEntityCode, lRecordRef));
                    lintCounter += 1;
                until (lRecordRef.Next() = 0) or (lintCounter > lPageSize);
        if pPageIndex = 1 then
            repeat
                pJARecords.Add(GetEntityFieldValues(pTableNo, pEntityCode, lRecordRef));
                lintCounter += 1;
            until (lRecordRef.Next() = 0) or (lintCounter > lPageSize);
    end;

    local procedure GetEntityFieldValues(pTableNo: Integer; pEntityCode: Code[20]; pRecordRef: RecordRef): JsonArray
    var
        lField: Record Field;
        lfieldRef: FieldRef;
        lBigInteger: BigInteger;
        lBoolean: Boolean;
        lDecimal: Decimal;
        linteger: Integer;
        lJAFieldValues: JsonArray;
        lFieldFilter: Text;
    begin
        lFieldFilter := '';

        lField.Reset();
        lField.SetRange(TableNo, pTableNo);
        lField.SetRange(Enabled, true);
        lField.SetRange(ObsoleteState, lField.ObsoleteState::No);

        if pEntityCode <> '' then begin
            //get table keys
            EntityMgmt.GetFieldFilter(pTableNo, pEntityCode, lFieldFilter);
            lField.SetFilter("No.", lFieldFilter);
        end;

        if lField.FindSet() then
            repeat
                lFieldRef := pRecordRef.Field(lField."No.");

                if lfieldRef.Class = lfieldRef.Class::FlowField then
                    lfieldRef.CalcField();

                case lfield.Type of
                    lfield.Type::BigInteger,
                    lfield.Type::Integer:
                        begin
                            lBigInteger := lFieldRef.Value;
                            lJAFieldValues.Add(lBigInteger);
                        end;
                    lfield.Type::Duration,
                    lfield.Type::Decimal:
                        begin
                            lDecimal := lFieldRef.Value;
                            lJAFieldValues.Add(lDecimal);
                        end;
                    lfield.Type::Code,
                    lfield.Type::DateFormula,
                    lfield.Type::GUID,
                    lfield.Type::OemCode,
                    lfield.Type::OemText,
                    lfield.Type::TableFilter,
                    lfield.Type::Text:
                        lJAFieldValues.Add(format(lFieldRef.Value, 0, 9));
                    lfield.Type::Date,
                    lfield.Type::DateTime,
                    lfield.Type::Time:
                        lJAFieldValues.Add(format(lFieldRef.Value, 0, 9));
                    lfield.Type::Boolean:
                        begin
                            lBoolean := lFieldRef.Value;
                            lJAFieldValues.Add(lBoolean);
                        end;
                    lfield.Type::Option:
                        begin
                            linteger := lfieldRef.Value;
                            linteger += 1;
                            lJAFieldValues.Add(lfieldRef.GetEnumValueName(linteger));
                        end;
                    lfield.Type::Binary,
                    lfield.Type::BLOB,
                    lfield.Type::Media,
                    lfield.type::MediaSet,
                    lfield.Type::RecordID:
                        lJAFieldValues.Add('Not Implemented');
                end;
            until lField.Next() = 0;

        exit(lJAFieldValues);
    end;

    procedure WriteData(pTableNo: Integer; var pEntity: Record "TNP Entity Header"; Activity: Text; pFieldValueArray: text; pIDFilterString: Text)
    var
        // lEntityFields: Record "TNP Entity Field" temporary;
        lRecordRef: RecordRef;
        lJAFieldValue: JsonArray;
        InsertAllowed: Boolean;
        InsertAfterPK: Boolean;
        InsertTrigger: Boolean;
        ModifyTriggerOnInsert: Boolean;
        ModifyAllowed: Boolean;
        ModifyTriggerOnModify: Boolean;
        DeleteAllowed: Boolean;
        DeleteTrigger: Boolean;
        RenameAllowed: Boolean;
        RenameTrigger: Boolean;
    begin
        InsertAllowed := true;
        InsertAfterPK := false;
        InsertTrigger := true;
        ModifyTriggerOnInsert := true;
        ModifyAllowed := true;
        ModifyTriggerOnModify := true;
        DeleteAllowed := true;
        DeleteTrigger := true;
        RenameAllowed := true;
        RenameTrigger := true;

        if pEntity."Entity Code" <> '' then begin
            InsertAllowed := pEntity."Insert Allowed";
            InsertAfterPK := pEntity."Insert After Primary Key";
            InsertTrigger := not pEntity."No Insert Trigger";
            ModifyTriggerOnInsert := not pEntity."No Modify Trigger - Insert";
            ModifyAllowed := pEntity."Modify Allowed";
            ModifyTriggerOnModify := pEntity."No Modify Trigger - Modify";
            DeleteAllowed := pEntity."Delete Allowed";
            DeleteTrigger := not pEntity."No Delete Trigger";
            RenameAllowed := pEntity."Rename Allowed";
            RenameTrigger := not pEntity."No Rename Trigger";
        end;

        lJAFieldValue.ReadFrom(pFieldValueArray);

        // EntityMgmt.GetFieldFilter(pTableNo, pEntity."Entity Code", lEntityFields);

        lRecordRef.Open(pTableNo);

        case Activity of
            'Insert':
                begin
                    if not InsertAllowed then Error('Insert not allowed for entity %1', pEntity."Entity Code");

                    if InsertAfterPK then
                        // EntityMgmt.InitSetKeys(lRecordRef, pEntity."Entity Code", lJAFieldValue);
                        this.EntityMgmt.InsertOp(lRecordRef, InsertTrigger);
                    this.EntityMgmt.SetFields(lRecordRef, pEntity."Entity Code", pTableNo, lJAFieldValue, pIDFilterString);
                    if InsertAfterPK then
                        this.EntityMgmt.ModifyOp(lRecordRef, ModifyTriggerOnInsert)
                    else
                        this.EntityMgmt.InsertOp(lRecordRef, InsertTrigger);
                end;
            'Modify':
                begin
                    if not ModifyAllowed then Error('Modify not allowed for entity %1', pEntity."Entity Code");
                    this.EntityMgmt.SearchKeys(lRecordRef, pTableNo, lJAFieldValue);
                    this.EntityMgmt.FindOp(lRecordRef);
                    this.EntityMgmt.SetFields(lRecordRef, pEntity."Entity Code", pTableNo, lJAFieldValue, pIDFilterString);
                    this.EntityMgmt.ModifyOp(lRecordRef, ModifyTriggerOnModify);
                end;
            'Delete':
                begin
                    if not DeleteAllowed then Error('Delete not allowed for entity %1', pEntity."Entity Code");
                    this.EntityMgmt.SearchKeys(lRecordRef, pTableNo, lJAFieldValue);
                    this.EntityMgmt.FindOp(lRecordRef);
                    this.EntityMgmt.DeleteOp(lRecordRef, DeleteTrigger);
                end;
        end;
    end;

    procedure searchRelatedTableRecord(pTableNo: Integer; pSearchTerm: Text): Text
    var
        field: Record Field;
        lRecordRef: RecordRef;
        lFieldRef: FieldRef;
        lSearchObject: JsonObject;
        searchResult: Text;
    begin
        lRecordRef.Open(pTableNo);
        field.Reset();
        field.SetRange(TableNo, pTableNo);
        field.SetRange(IsPartOfPrimaryKey, true);
        field.SetRange(field.ObsoleteState, field.ObsoleteState::No);
        if field.FindSet() then
            repeat
                lFieldRef := lRecordRef.Field(field."No.");

                lFieldRef.SetFilter(pSearchTerm);
                if lRecordRef.FindSet(false) then begin
                    lSearchObject.Add('value', Format(lFieldRef.Value));
                    lSearchObject.WriteTo(searchResult);
                    exit(searchResult);
                end;

                lFieldRef.SetFilter('*' + pSearchTerm);
                if lRecordRef.FindSet(false) then begin
                    lSearchObject.Add('value', Format(lFieldRef.Value));
                    lSearchObject.WriteTo(searchResult);
                    exit(searchResult);
                end;

                lFieldRef.SetFilter('*' + pSearchTerm + '*');
                if lRecordRef.FindSet(false) then begin
                    lSearchObject.Add('value', Format(lFieldRef.Value));
                    lSearchObject.WriteTo(searchResult);
                    exit(searchResult);
                end;
                lSearchObject.Add('error', 'No results found');
                lSearchObject.WriteTo(searchResult);
                exit(searchResult);
            until field.Next() = 0;
    end;

    procedure LoginUser(pUserEmail: Text[250]; pPassword: Text[250]): Text
    var
        PortalUser: Record "TNP Portal User";
        lJOData: JsonObject;
        lJResult: Text;
    begin

        if not this.PortalUserMgmt.ValidatePasswordByEmail(pUserEmail, pPassword, PortalUser) then
            error(this.UserNotFoundSecureErr);

        lJOData.Add('userId', PortalUser."User ID");
        lJOData.Add('fullName', PortalUser."Full Name");
        lJOData.Add('phoneNo', PortalUser."Phone No.");

        lJOData.WriteTo(lJResult);
        exit(lJResult);
    end;

    procedure SetPassword(pUserEmail: Text[250]; pPassword: Text[250]): Boolean
    var
        PortalUser: Record "TNP Portal User";
    begin
        if not PortalUser.FindUserByEmail(pUserEmail) then
            error(this.UserNotFoundSecureErr);

        this.PortalUserMgmt.CreatePassword(PortalUser, pPassword);
        exit(true);
    end;

    #endregion Json Methods
}