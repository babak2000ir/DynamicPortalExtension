codeunit 60001 "TNP Entity Mgmt."
{

    procedure GetFieldFilter(pTableNo: Integer; EntityCode: Code[20]; var FilterString: Text)
    var
        TempEntityFieldsDummy: Record "TNP Entity Field" temporary;
    begin
        this.GetFieldFilter(pTableNo, EntityCode, FilterString, TempEntityFieldsDummy);
    end;

    procedure GetFieldFilter(pTableNo: Integer; EntityCode: Code[20]; var pEntityFields: Record "TNP Entity Field" temporary)
    var
        lFilterStringDummy: Text;
    begin
        this.GetFieldFilter(pTableNo, EntityCode, lFilterStringDummy, pEntityFields);
    end;

    procedure GetFieldFilter(pTableNo: Integer; EntityCode: Code[20]; var FilterString: Text; var pEntityFields: Record "TNP Entity Field" temporary)
    var
        lEntityField: Record "TNP Entity Field";
        keyFieldsList: List of [Integer];
        KeyFieldId: Integer;
    begin
        FilterString := '';

        pEntityFields.Reset();
        pEntityFields.DeleteAll();

        this.GetTableKeyFieldsFilter(pTableNo, FilterString, KeyFieldsList);

        foreach KeyFieldId in KeyFieldsList do begin
            pEntityFields.init();
            pEntityFields."Entity Code" := EntityCode;
            pEntityFields."Field ID" := KeyFieldId;
            pEntityFields."Read Only" := TRUE;
            pEntityFields."Primary Key" := TRUE;
            pEntityFields.Insert();
        end;

        lEntityField.Reset();
        lEntityField.SetRange("Entity Code", EntityCode);
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
            until lEntityField.Next() = 0;
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

    procedure InitSetKeys(pRecordRef: RecordRef; pEntityCode: Code[20]; var pJAFieldValue: JsonArray)
    var
        lEntityFields: Record "TNP Entity Field";
        lFieldRef: FieldRef;
        lJTFieldValue: JsonToken;
        typeQuery: Text;
        valueQuery: Text;
    begin
        //Init
        pRecordRef.Init();

        //Set Keys
        lEntityFields.Reset();
        lEntityFields.SetRange("Entity Code", pEntityCode);
        lEntityFields.SetRange("Primary Key", true);
        if lEntityFields.FindSet() then
            repeat
                lFieldRef := pRecordRef.Field(lEntityFields."Field ID");
                valueQuery := '[?(@.id==''' + Format(lEntityFields."Field ID") + ''')].value';
                typeQuery := '[?(@.id==''' + Format(lEntityFields."Field ID") + ''')].type';
                pJAFieldValue.SelectToken(valueQuery, lJTFieldValue);
                convertJsonValueToFieldType(pJAFieldValue, lFieldRef, lJTFieldValue, typeQuery);
            until lEntityFields.Next() = 0;
    end;

    procedure SetFields(pRecordRef: RecordRef; pEntityCode: Code[20]; pTableNo: Integer; var pJAFieldValue: JsonArray; pIDFilterString: Text)
    var
        field: Record Field;
        lEntityFields: Record "TNP Entity Field";
        lFieldRef: FieldRef;
        lJTFieldValue: JsonToken;
        typeQuery: Text;
        valueQuery: Text;
    begin
        //Set Fields
        if pEntityCode <> '' then begin
            lEntityFields.Reset();
            lEntityFields.SetRange("Entity Code", pEntityCode);
            lEntityFields.SetRange("Primary Key", false);
            lEntityFields.SetRange("Read Only", false);
            lEntityFields.setFilter("Field ID", pIDFilterString);
            if lEntityFields.FindSet() then
                repeat
                    lFieldRef := pRecordRef.Field(lEntityFields."Field ID");
                    valueQuery := '[?(@.id==''' + Format(lEntityFields."Field ID") + ''')].value';
                    typeQuery := '[?(@.id==''' + Format(lEntityFields."Field ID") + ''')].type';
                    pJAFieldValue.SelectToken(valueQuery, lJTFieldValue);
                    convertJsonValueToFieldType(pJAFieldValue, lFieldRef, lJTFieldValue, typeQuery);
                until lEntityFields.Next() = 0;
        end
        else begin
            field.Reset();
            field.SetRange(TableNo, pTableNo);
            field.SetRange(IsPartOfPrimaryKey, false);
            field.SetRange(field.ObsoleteState, field.ObsoleteState::No);
            field.SetFilter("No.", pIDFilterString);
            if field.FindSet() then
                repeat
                    lFieldRef := pRecordRef.Field(field."No.");
                    valueQuery := '[?(@.id==''' + Format(field."No.") + ''')].value';
                    typeQuery := '[?(@.id==''' + Format(field."No.") + ''')].type';
                    if pJAFieldValue.SelectToken(valueQuery, lJTFieldValue) then
                        convertJsonValueToFieldType(pJAFieldValue, lFieldRef, lJTFieldValue, typeQuery);
                until field.Next() = 0;
        end;
    end;

    local procedure convertJsonValueToFieldType(var pJAFieldValue: JsonArray; var lFieldRef: FieldRef; lJTFieldValue: JsonToken; typeQuery: Text)
    var
        lJTFieldType: JsonToken;
        optionIndex: Integer;
    begin
        if pJAFieldValue.SelectToken(typeQuery, lJTFieldType) then
            case lJTFieldType.AsValue().AsText() of
                'Text':
                    lFieldRef.Validate(lJTFieldValue.AsValue().AsText());
                'DateTime':
                    lFieldRef.Validate(lJTFieldValue.AsValue().AsDateTime());
                'Date':
                    lFieldRef.Validate(lJTFieldValue.AsValue().AsDate());
                'Time':
                    lFieldRef.Validate(lJTFieldValue.AsValue().AsTime());
                'Boolean':
                    if (lFieldRef.Class = FieldClass::FlowField) then
                        lFieldRef.CalcField()
                    else
                        lFieldRef.Validate(lJTFieldValue.AsValue().AsBoolean());
                'Integer':
                    lFieldRef.Validate(lJTFieldValue.AsValue().AsInteger());
                'Decimal':
                    lFieldRef.Validate(lJTFieldValue.AsValue().AsDecimal());
                'Code':
                    lFieldRef.Validate(lJTFieldValue.AsValue().AsCode());
                'Option':
                    begin
                        optionIndex := lFieldRef.OptionMembers.Split(',').IndexOf(lJTFieldValue.AsValue().AsText());
                        lFieldRef.Validate(optionIndex - 1);
                    end;
                'GUID':
                    lFieldRef.Validate(lJTFieldValue.AsValue().AsByte());
                else
                    lFieldRef.Validate(lJTFieldValue.AsValue());
            end;
    end;

    local procedure findRecordByKeys(var pJAFieldValue: JsonArray; var lFieldRef: FieldRef; lJTFieldValue: JsonToken; typeQuery: Text)
    var
        lJTFieldType: JsonToken;
        optionValue: Integer;
    begin
        if pJAFieldValue.SelectToken(typeQuery, lJTFieldType) then
            case lJTFieldType.AsValue().AsText() of
                'Text':
                    lFieldRef.setRange(lJTFieldValue.AsValue().AsText());
                'DateTime':
                    lFieldRef.setRange(lJTFieldValue.AsValue().AsDateTime());
                'Date':
                    lFieldRef.setRange(lJTFieldValue.AsValue().AsDate());
                'Time':
                    lFieldRef.setRange(lJTFieldValue.AsValue().AsTime());
                'Boolean':
                    if (lFieldRef.Class = FieldClass::FlowField) then
                        lFieldRef.CalcField()
                    else
                        lFieldRef.setRange(lJTFieldValue.AsValue().AsBoolean());
                'Integer':
                    lFieldRef.setRange(lJTFieldValue.AsValue().AsInteger());
                'Decimal':
                    lFieldRef.setRange(lJTFieldValue.AsValue().AsDecimal());
                'Code':
                    lFieldRef.setRange(lJTFieldValue.AsValue().AsCode());
                'Option':
                    begin
                        optionValue := lFieldRef.OptionMembers.Split(',').IndexOf(lJTFieldValue.AsValue().AsText());
                        lFieldRef.setRange(optionValue - 1);
                    end;
                'GUID':
                    lFieldRef.setRange(lJTFieldValue.AsValue().AsByte());
                else
                    lFieldRef.setRange(lJTFieldValue.AsValue());
            end;
    end;

    procedure InsertOp(pRecordRef: RecordRef; pRunTrigger: Boolean)
    begin
        //Insert
        pRecordRef.Insert(pRunTrigger)
    end;

    procedure SearchKeys(pRecordRef: RecordRef; pTableNo: Integer; var pJAFieldValue: JsonArray)
    var
        field: Record Field;
        lFieldRef: FieldRef;
        lJTFieldValue: JsonToken;
        typeQuery: Text;
        valueQuery: Text;
    begin
        field.Reset();
        field.SetRange(TableNo, pTableNo);
        field.SetRange(IsPartOfPrimaryKey, true);
        field.SetRange(field.ObsoleteState, field.ObsoleteState::No);
        if field.FindSet() then
            repeat
                lFieldRef := pRecordRef.Field(field."No.");
                valueQuery := '[?(@.id==''' + Format(field."No.") + ''')].value';
                typeQuery := '[?(@.id==''' + Format(field."No.") + ''')].type';
                pJAFieldValue.SelectToken(valueQuery, lJTFieldValue);
                findRecordByKeys(pJAFieldValue, lFieldRef, lJTFieldValue, typeQuery);
            until field.Next() = 0;
    end;

    procedure FindOp(pRecordRef: RecordRef)
    begin
        //Find
        pRecordRef.FindFirst();
    end;

    procedure ModifyOp(pRecordRef: RecordRef; pRunTrigger: Boolean)
    begin
        //Modify
        pRecordRef.Modify(pRunTrigger);
    end;


    procedure DeleteOp(pRecordRef: RecordRef; pRunTrigger: Boolean)
    begin
        //Delete
        pRecordRef.Delete(pRunTrigger);
    end;

    local procedure FilterRecords(var pRecordRef: RecordRef; pFilterString: Text)
    var
        lFieldRef: FieldRef;
        lCounter: Integer;
        lfieldIdx: Integer;
        lintValue: Integer;
        lSplitFilter: List of [Text];
        lValue: Text;
    begin
        lSplitFilter := pFilterString.Split(',');
        for lCounter := 1 to lSplitFilter.Count / 2 do begin
            lSplitFilter.Get(lCounter * 2 - 1, lValue);
            Evaluate(lfieldIdx, lValue);
            lSplitFilter.Get(lCounter * 2, lValue);
            lFieldRef := pRecordRef.Field(lfieldIdx);

            case lFieldRef.Type of
                lfieldRef.Type::Option:
                    begin
                        lintValue := lFieldRef.OptionMembers.Split(',').IndexOf(lValue) - 1;
                        lFieldRef.SetFilter('=%1', lintValue);
                    end;
                else
                    lFieldRef.SetFilter('=%1', lValue);
            end;
        end;
    end;
}