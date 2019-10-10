function xmlStruct = ReadXMLHeader(xmlString)
    re = '<(?<property>[^/?<>]*)>(?<data>[^/?<>]*)(</\k<property>>)*';

    matches = regexp(xmlString,re, 'names');
    xmlStruct = struct();
    i = 1;
    while i <= length(matches)

        if strcmp(strtrim(matches(i).data), '')
            sub_struct = matches(i).property;
            i = i + 1;
            while i <= length(matches) && ~strcmp(strtrim(matches(i).data), '')
                xmlStruct.(sub_struct).(matches(i).property) = StringOrNumber(matches(i).data);
                i = i + 1;
            end
        else
            xmlStruct.(matches(i).property) = StringOrNumber(matches(i).data);
            i = i + 1;
        end

    end
    
    % nested functions ====================================================
    function outValue = StringOrNumber(str2test)

        if (~isnan(str2double(str2test))) % str2test is only numbers
            outValue = str2double(str2test);
        else
            outValue = str2test;
        end

    end    
end

