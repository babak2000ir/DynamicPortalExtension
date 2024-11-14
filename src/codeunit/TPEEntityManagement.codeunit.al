codeunit 60001 "TPE Entity Management"
{
    var
        TechnicalOptionTxt: TextConst ENU = '%1';

    #Region Json Methods
    procedure GetEntities() JOResult: JsonObject
    var
        Entities: Record "TNP Entity Header";
        lAllObjWithCaption: Record AllObjWithCaption;
        lJAEntities: JsonArray;
        lJOEntity: JsonObject;
        TableIdsList: List of [Integer];
        lJARelations: JsonArray;
    begin
        Clear(TableIdsList);

        Entities.Reset();
        Entities.SetAutoCalcFields("Table Name");
        if Entities.FindSet(false) then
            repeat
                TableIdsList.Add(Entities."Table ID");

                Clear(lJOEntity);
                this.GetTable(Entities."Entity Code", Entities."Table ID", Entities."Table Name", Entities."Entity Name", Entities."Insert Allowed", Entities."Modify Allowed", Entities."Delete Allowed", lJOEntity);

                lJARelations := this.GetTableRelations(Entities."Entity Code");
                if lJARelations.Count > 0 then
                    lJOEntity.Add('relations', lJARelations);

                lJAEntities.Add(lJOEntity);
            until Entities.Next() = 0;

        lAllObjWithCaption.Reset();
        lAllObjWithCaption.SetRange("Object Type", lAllObjWithCaption."Object Type"::Table);
        lAllObjWithCaption.SetRange("Object Subtype", 'Normal');
        if lAllObjWithCaption.FindSet() then
            repeat
                Clear(lJOEntity);
                if not TableIdsList.Contains(lAllObjWithCaption."Object ID") then begin
                    this.GetTable('', lAllObjWithCaption."Object ID", lAllObjWithCaption."Object Name", lAllObjWithCaption."Object Caption", false, false, false, lJOEntity);
                    lJAEntities.Add(lJOEntity);
                end;
            until lAllObjWithCaption.Next() = 0;

        JOResult.Add('entities', lJAEntities);
    end;

    procedure GetTable(pEntityCode: Code[20]; TableId: Integer; TableName: Text; Caption: Text; InsertAllowed: Boolean; ModifyAllowed: Boolean; DeleteAllowed: Boolean; var pJOTable: JsonObject)
    begin
        pJOTable.Add('id', TableId);
        pJOTable.Add('name', TableName);
        if pEntityCode <> '' then
            pJOTable.Add('entityCode', pEntityCode);
        pJOTable.Add('caption', Caption);
        pJOTable.Add('insertAllowed', InsertAllowed);
        pJOTable.Add('modifyAllowed', ModifyAllowed);
        pJOTable.Add('deleteAllowed', DeleteAllowed);
        pJOTable.Add('fields', this.GetTableFields(TableId, pEntityCode));
    end;

    procedure GetTableRelations(pEntityCode: Code[20]) JATables: JsonArray
    var
        lEntityRelationTable: Record "TNP Entity Related Table";
        lEntity: Record "TNP Entity Header";
        lEntityRelationFilter: record "TNP Ent. Rel. Table Filter";
        pJOTable: JsonObject;
        lJOEntityRelations: JsonObject;
        lJAEntityRelations: JsonArray;
    begin
        lEntityRelationTable.Reset();
        lEntityRelationTable.SetRange("Entity Code", pEntityCode);
        lEntityRelationTable.SetAutoCalcFields("Related Table Name");
        if lEntityRelationTable.FindSet() then
            repeat
                Clear(pJOTable);
                if (lEntityRelationTable."Related Entity" <> '') and lEntity.Get(lEntityRelationTable."Related Entity") then
                    this.GetTable(lEntityRelationTable."Related Entity",
                        lEntityRelationTable."Related Table ID", lEntityRelationTable."Related Table Name", lEntity."Entity Name",
                        lEntity."Insert Allowed", lEntity."Modify Allowed", lEntity."Delete Allowed",
                        pJOTable)
                else
                    this.GetTable('',
                        lEntityRelationTable."Related Table ID", lEntityRelationTable."Related Table Name", lEntityRelationTable."Related Table Name",
                        false, false, false,
                        pJOTable);

                Clear(lJAEntityRelations);
                lEntityRelationFilter.Reset();
                lEntityRelationFilter.SetRange("Entity Code", pEntityCode);
                lEntityRelationFilter.SetRange("Related Table ID", lEntityRelationTable."Related Table ID");
                if lEntityRelationFilter.FindSet() then
                    repeat
                        clear(lJOEntityRelations);
                        lJOEntityRelations.Add('entityFieldId', lEntityRelationFilter."Entity Header Field ID");
                        lJOEntityRelations.Add('fieldRelation', StrSubstNo(this.TechnicalOptionTxt, lEntityRelationFilter."Field Relation"));
                        lJOEntityRelations.Add('relationFieldId', lEntityRelationFilter."Related Table Field ID");
                        lJAEntityRelations.Add(lJOEntityRelations);
                    until lEntityRelationFilter.Next() = 0;

                pJOTable.Add('relationFilters', lJAEntityRelations);
                JATables.Add(pJOTable);
            until lEntityRelationTable.Next() = 0;
    end;

    procedure GetTableFields(pTableNo: Integer; EntityCode: Code[20]): JsonArray
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
            this.GetFieldFilter(EntityCode, lFieldFilter, TempEntityFields);
            lField.SetFilter("No.", lFieldFilter);
        end;
        lField.SetRange(TableNo, pTableNo);
        lField.SetRange(Enabled, true);
        lField.SetRange(ObsoleteState, lField.ObsoleteState::No);
        if lField.FindSet() then
            repeat
                lJAFields.Add(this.GetEntityFieldInfo(lField, EntityCode));
            until lField.Next() = 0;

        exit(lJAFields);
    end;

    procedure GetEntityFieldInfo(pField: Record Field; pEntityCode: Code[20]): JsonObject
    var
        pEntityFields: Record "TNP Entity Field";
        lJOField: JsonObject;
    begin
        lJOField.Add('id', pField."No.");
        lJOField.Add('name', pField.FieldName);
        lJOField.Add('caption', pField."Field Caption");
        lJOField.Add('type', StrSubstNo(this.TechnicalOptionTxt, pField.Type));
        lJOField.Add('length', pField.Len);
        lJOField.Add('class', StrSubstNo(this.TechnicalOptionTxt, pField.Class));

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

    procedure GetEntityData(pEntityCode: Code[20]; pView: Text; pPageSize: Integer; pPageIndex: Integer) JOResult: JsonObject
    var
        lPageCount: Integer;
        lJARecords: JsonArray;
        lJAPaging, lJOData : JsonObject;
    begin
        this.GetEntityRecords(pEntityCode, pView, lJARecords, pPageSize, pPageIndex, lPageCount);

        lJAPaging.Add('pageIndex', pPageIndex);
        lJAPaging.Add('pageCount', lPageCount);
        lJAPaging.Add('pageSize', pPageSize);

        lJOData.Add('paging', lJAPaging);
        lJOData.Add('records', lJARecords);
        if pEntityCode <> '' then
            lJOData.Add('entityCode', this.GetEntityCode(pEntityCode));

        JOResult.Add('data', lJOData);
    end;

    procedure GetEntityRecords(pEntityCode: Code[20]; pView: Text; var pJARecords: JsonArray; pPageSize: integer; pPageIndex: Integer; var pPageCount: Integer)
    var
        lRecordRef: RecordRef;
        lintCounter: Integer;
        lTableId: Integer;
        lRecordCount: Integer;
    begin
        if pPageSize < 1 then
            pPageSize := 10;

        Clear(pJARecords);

        lTableId := this.GetTableId(pEntityCode);

        lRecordRef.Open(lTableId);
        if pView <> '' then
            lRecordRef.SetView(pView);

        // Filter BY RelationFilter Field ID
        /* if lJFilterValue.ReadFrom(pFilterParams) then
            if lJFilterValue.Count > 0 then begin
                lEntityRelationFilter.Reset();
                lEntityRelationFilter.SetRange("Entity Code", pRelatedEntityCode);
                lEntityRelationFilter.SetRange("Related Table ID", lTableId);
                if lEntityRelationFilter.FindSet() then
                    repeat
                        lFieldRef := lRecordRef.Field(lEntityRelationFilter."Related Table Field ID");
                        valueQuery := '[?(@.id==''' + Format(lEntityRelationFilter."Related Table Field ID") + ''')].value';
                        lJFilterValue.SelectToken(valueQuery, lJTFieldValue);
                        lFieldRef.SetFilter(lJTFieldValue.AsValue().AsText());
                    until lEntityRelationFilter.Next() = 0;
            end; */

        lRecordCount := lRecordRef.Count();
        pPageCount := (lRecordCount div pPageSize);
        if (lRecordCount mod pPageSize) > 0 then
            pPageCount += 1;

        if pPageIndex > pPageCount then
            exit;

        lintCounter := 1;
        lRecordRef.FindSet();
        if pPageIndex > 1 then
            if lRecordRef.next((pPageIndex - 1) * pPageSize) > 0 then
                repeat
                    pJARecords.Add(this.GetEntityFieldValues(pEntityCode, lRecordRef));
                    lintCounter += 1;
                until (lRecordRef.Next() = 0) or (lintCounter > pPageSize + 1);
        if pPageIndex = 1 then
            repeat
                pJARecords.Add(this.GetEntityFieldValues(pEntityCode, lRecordRef));
                lintCounter += 1;
            until (lRecordRef.Next() = 0) or (lintCounter > pPageSize);
    end;

    procedure GetEntityFieldValues(pEntityCode: Code[20]; pRecordRef: RecordRef): JsonArray
    var
        lField: Record Field;
        lfieldRef: FieldRef;
        lBigInteger: BigInteger;
        lBoolean: Boolean;
        lDecimal: Decimal;
        lTableId: Integer;
        linteger: Integer;
        lJAFieldValues: JsonArray;
    begin
        lTableId := this.GetTableId(pEntityCode);

        lField.Reset();
        lField.SetRange(TableNo, lTableId);
        lField.SetRange(Enabled, true);
        lField.SetRange(ObsoleteState, lField.ObsoleteState::No);
        lField.SetFilter("No.", this.GetFieldFilter(pEntityCode));

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

    procedure WriteData(pEntityCode: Code[20]; Activity: Text; pFieldValueArray: text)
    var
        lEntity: Record "TNP Entity Header";
        lRecordRef: RecordRef;
        DeleteAllowed: Boolean;
        DeleteTrigger: Boolean;
        InsertAfterPK: Boolean;
        InsertAllowed: Boolean;
        InsertTrigger: Boolean;
        ModifyAllowed: Boolean;
        ModifyTriggerOnInsert: Boolean;
        ModifyTriggerOnModify: Boolean;
        //RenameAllowed: Boolean;
        //RenameTrigger: Boolean;
        lTableNo: Integer;
        lJAFieldValue: JsonArray;
    begin
        InsertAllowed := true;
        InsertAfterPK := false;
        InsertTrigger := true;
        ModifyTriggerOnInsert := true;
        ModifyAllowed := true;
        ModifyTriggerOnModify := true;
        DeleteAllowed := true;
        DeleteTrigger := true;
        //RenameAllowed := true;
        //RenameTrigger := true;

        if lEntity.Get(this.GetEntityCode(pEntityCode)) then begin
            InsertAllowed := lEntity."Insert Allowed";
            InsertAfterPK := lEntity."Insert After Primary Key";
            InsertTrigger := not lEntity."No Insert Trigger";
            ModifyTriggerOnInsert := not lEntity."No Modify Trigger - Insert";
            ModifyAllowed := lEntity."Modify Allowed";
            ModifyTriggerOnModify := lEntity."No Modify Trigger - Modify";
            DeleteAllowed := lEntity."Delete Allowed";
            DeleteTrigger := not lEntity."No Delete Trigger";
            //RenameAllowed := lEntity."Rename Allowed";
            //RenameTrigger := not lEntity."No Rename Trigger";
        end;

        lJAFieldValue.ReadFrom(pFieldValueArray);

        lTableNo := this.GetTableId(pEntityCode);
        lRecordRef.Open(lTableNo);

        case LowerCase(Activity) of
            'insert':
                begin
                    if not InsertAllowed then Error('Insert not allowed for %1', pEntityCode);

                    this.InitSetKeys(lRecordRef, lJAFieldValue);

                    if InsertAfterPK then
                        lRecordRef.Insert(InsertTrigger);

                    this.ValidateFields(lRecordRef, pEntityCode, lJAFieldValue);

                    if InsertAfterPK then
                        lRecordRef.Modify(ModifyTriggerOnInsert)
                    else
                        lRecordRef.Insert(InsertTrigger);
                end;
            'modify':
                begin
                    if not ModifyAllowed then Error('Modify not allowed for %1', pEntityCode);

                    this.FilterFields(lRecordRef, lJAFieldValue);
                    lRecordRef.FindFirst();
                    this.ValidateFields(lRecordRef, pEntityCode, lJAFieldValue);
                    lRecordRef.Modify(ModifyTriggerOnModify);
                end;
            'delete':
                begin
                    if not DeleteAllowed then Error('Delete not allowed for %1', pEntityCode);

                    this.FilterFields(lRecordRef, lJAFieldValue);
                    lRecordRef.Delete(DeleteTrigger);
                end;
        end;
    end;

    #endregion Json Methods
    procedure GetFieldFilter(pEntityCode: Code[20]) FilterString: Text
    var
        TempEntityFieldsDummy: Record "TNP Entity Field" temporary;
    begin
        this.GetFieldFilter(pEntityCode, FilterString, TempEntityFieldsDummy);
    end;

    procedure GetFieldFilter(EntityCode: Code[20]; var FilterString: Text; var pEntityFields: Record "TNP Entity Field" temporary)
    var
        lEntityField: Record "TNP Entity Field";
        keyFieldsList: List of [Integer];
        KeyFieldId: Integer;
        lTableId: Integer;
    begin
        lTableId := this.GetTableId(EntityCode);

        FilterString := '';

        pEntityFields.Reset();
        pEntityFields.DeleteAll();

        this.GetTableKeyFieldsFilter(lTableId, FilterString, KeyFieldsList);

        foreach KeyFieldId in KeyFieldsList do begin
            pEntityFields.init();
            pEntityFields."Entity Code" := EntityCode;
            pEntityFields."Field ID" := KeyFieldId;
            pEntityFields."Read Only" := true;
            pEntityFields."Primary Key" := true;
            pEntityFields.Insert();
        end;

        lEntityField.Reset();
        lEntityField.SetRange("Entity Code", this.GetEntityCode(EntityCode));
        if lEntityField.FindSet() then
            repeat
                if StrPos(FilterString, format(lEntityField."Field ID")) = 0 then begin
                    if FilterString = '' then
                        FilterString := format(lEntityField."Field ID")
                    else
                        FilterString += '|' + Format(lEntityField."Field ID");

                    pEntityFields.init();
                    pEntityFields.TransferFields(lEntityField);
                    pEntityFields.Insert();
                end;
            until lEntityField.Next() = 0
        else
            FilterString := '';
    end;

    procedure GetTableKeyFieldsFilter(pTableNo: Integer; var FilterString: Text; var KeyFieldsList: List of [Integer])
    var
        lFields: Record Field;
    begin
        Clear(KeyFieldsList);
        lFields.Reset();
        lFields.SetRange(TableNo, pTableNo);
        lFields.SetRange(IsPartOfPrimaryKey, TRUE);
        if lFields.FindSet() then
            repeat
                KeyFieldsList.Add(lFields."No.");
                if FilterString = '' then
                    FilterString := format(lFields."No.")
                else
                    FilterString += '|' + Format(lFields."No.");
            until lFields.Next() = 0;
    end;

    procedure InitSetKeys(pRecordRef: RecordRef; var pJAFieldValue: JsonArray)
    var
        Field: Record Field;
        lFieldRef: FieldRef;
    begin
        //Init
        pRecordRef.Init();

        //Set Keys
        Field.Reset();
        Field.SetRange(TableNo, pRecordRef.RecordId.TableNo);
        Field.SetRange(IsPartOfPrimaryKey, true);
        Field.SetRange(field.ObsoleteState, field.ObsoleteState::No);
        if Field.FindSet() then
            repeat
                lFieldRef := pRecordRef.Field(Field."No.");
                lFieldRef.Validate(this.GetFieldValue(pRecordRef.RecordId.TableNo, Field, pJAFieldValue));
            until Field.Next() = 0;
    end;

    procedure ValidateFields(pRecordRef: RecordRef; pEntityCode: Code[20]; var pJAFieldValue: JsonArray)
    var
        Field: Record Field;
        lEntityFields: Record "TNP Entity Field";
        lFieldRef: FieldRef;
        lEntityCode: Code[20];
    begin
        lEntityCode := this.GetEntityCode(pEntityCode);

        //Set Fields
        if lEntityCode <> '' then begin
            lEntityFields.Reset();
            lEntityFields.SetRange("Entity Code", pEntityCode);
            lEntityFields.SetRange("Primary Key", false);
            lEntityFields.SetRange("Read Only", false);
            if lEntityFields.FindSet() then
                repeat
                    lFieldRef := pRecordRef.Field(lEntityFields."Field ID");
                    lFieldRef.Validate(this.GetFieldValue(pRecordRef.RecordId.TableNo, lEntityFields."Field ID", pJAFieldValue));
                until lEntityFields.Next() = 0;
        end else begin
            Field.Reset();
            Field.SetRange(TableNo, pRecordRef.RecordId.TableNo);
            Field.SetRange(IsPartOfPrimaryKey, false);
            Field.SetRange(field.ObsoleteState, field.ObsoleteState::No);
            if Field.FindSet() then
                repeat
                    lFieldRef := pRecordRef.Field(Field."No.");
                    lFieldRef.Validate(this.GetFieldValue(pRecordRef.RecordId.TableNo, Field, pJAFieldValue));
                until Field.Next() = 0;
        end;
    end;

    procedure FilterFields(pRecordRef: RecordRef; var pJAFieldValue: JsonArray)
    var
        Field: Record Field;
        lFieldRef: FieldRef;
    begin
        Field.Reset();
        Field.SetRange(TableNo, pRecordRef.RecordId.TableNo);
        Field.SetRange(IsPartOfPrimaryKey, true);
        Field.SetRange(field.ObsoleteState, field.ObsoleteState::No);
        if Field.FindSet() then
            repeat
                lFieldRef := pRecordRef.Field(Field."No.");
                lFieldRef.SetRange(this.GetFieldValue(pRecordRef.RecordId.TableNo, Field, pJAFieldValue));
            until Field.Next() = 0;
    end;

    procedure IsPrimaryKey(TableNo: Integer; FieldNo: Integer): Boolean
    var
        Field: Record Field;
    begin
        if Field.Get(TableNo, FieldNo) and Field.IsPartOfPrimaryKey then
            exit(true);
    end;

    procedure isFlowField(TableNo: Integer; FieldNo: Integer): Boolean
    var
        Field: Record Field;
    begin
        if Field.Get(TableNo, FieldNo) and (Field.Class = Field.Class::FlowField) then
            exit(true);
    end;

    procedure GetTableId(pEntityCode: Code[20]): Integer
    var
        lEntity: Record "TNP Entity Header";
        lTableId: Integer;
    begin
        if lEntity.Get(pEntityCode) then
            exit(lEntity."Table ID")
        else
            if Evaluate(lTableId, pEntityCode) then
                exit(lTableId)
            else
                Error('Entity not found');
    end;

    procedure GetEntityCode(pEntityCode: Code[20]): Code[20]
    var
        lEntity: Record "TNP Entity Header";
        lTableId: Integer;
    begin
        if lEntity.Get(pEntityCode) then
            exit(lEntity."Entity Code")
        else
            if Evaluate(lTableId, pEntityCode) then begin
                lEntity.Reset();
                lEntity.SetRange("Table ID", lTableId);
                if lEntity.FindFirst() then
                    exit(lEntity."Entity Code");
            end;
    end;

    procedure GetFieldValue(pTableId: Integer; pFieldId: Integer; pJAFieldsValue: JsonArray): Variant
    var
        lField: Record Field;
    begin
        lField.Get(pTableId, pFieldId);
        exit(this.GetFieldValue(pTableId, lField, pJAFieldsValue));
    end;

    procedure GetFieldValue(pTableId: Integer; pField: Record Field; pJAFieldsValue: JsonArray): Variant
    var
        lJTFieldValue: JsonToken;
        ValueQuery: Text;
    begin
        valueQuery := '$.[?(@.id==''' + Format(pField."No.") + ''')].value';
        pJAFieldsValue.SelectToken(valueQuery, lJTFieldValue);

        case pField.Type of
            pField.Type::Text:
                exit(lJTFieldValue.AsValue().AsText());
            pField.Type::DateTime:
                exit(lJTFieldValue.AsValue().AsDateTime());
            pField.Type::Date:
                exit(lJTFieldValue.AsValue().AsDate());
            pField.Type::Time:
                exit(lJTFieldValue.AsValue().AsTime());
            pField.Type::Boolean:
                exit(lJTFieldValue.AsValue().AsBoolean());
            pField.Type::Integer:
                exit(lJTFieldValue.AsValue().AsInteger());
            pField.Type::Decimal:
                exit(lJTFieldValue.AsValue().AsDecimal());
            pField.Type::Code:
                exit(lJTFieldValue.AsValue().AsCode());
            pField.Type::Option:
                exit(pField.OptionString.Split(',').IndexOf(lJTFieldValue.AsValue().AsText()) - 1);
            pField.Type::GUID:
                exit(lJTFieldValue.AsValue().AsText());
            else
                exit(lJTFieldValue.AsValue().AsText());
        end;
    end;
}