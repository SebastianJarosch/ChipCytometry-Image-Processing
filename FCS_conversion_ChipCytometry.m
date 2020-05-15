%% Get filenames to open and export files
filenameFL = 'FL_values.csv';
filenameChannels = 'channels.csv';
delimiter = ',';
startRow = 2;
endRow = inf;
    

%% Get data from channel info file created in ImageJ
% File should contain all channels listed in one colum and ChipID in the first row
fileID = fopen(filenameChannels,'r');
dataChannels = textscan(fileID, '%q', 'Delimiter', delimiter);
ChannelTable = dataChannels{1,1};
channels = length(ChannelTable);
ChannelInfo = reshape(ChannelTable, [1, channels]);
exportname = ChannelInfo(1)+".fcs";
ChannelInfo = ChannelInfo(2:end);
channels = length(ChannelInfo);
fclose(fileID);

%% Format string for each line of text:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%f%q%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%q%q%f%f%f%f%f%f%f%f%f%f%[^\n\r]';

%% Open the text file.
fileID = fopen(filenameFL,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Create output variable with all markers assigned to each ROI
ResultsTable = table(dataArray{1:end-1}, 'VariableNames', {'VarName1','Label','Area','Mean','StdDev','Min','Max','X','Y','XM','YM','Perim','BX','BY','Width','Height','Major','Minor','Angle','Circ','Feret','IntDen','Median','Skew','Kurt','VarName26','RawIntDen','Slice','FeretX','FeretY','FeretAngle','MinFeret','AR','Round','Solidity'});

cellno = length(ResultsTable{:,1})/channels;
allmeans = ResultsTable.Mean;
ResultsArray = reshape(allmeans,cellno,channels);
ResultsArray(:,channels+1) = ResultsTable.Area(1:cellno);
ResultsArray(:,channels+2) = ResultsTable.Circ(1:cellno);
ResultsArray(:,channels+3) = ResultsTable.X(1:cellno);
ResultsArray(:,channels+4) = ResultsTable.Y(1:cellno);
ResultsArray(:,channels+5) = ResultsTable.VarName1(1:cellno);

%% Generate channel names and write FCS file
additionalChannels = {'Area','Circ','CellsX','CellsY','Cell_identifier'};

TEXT.PnS = [ChannelInfo, additionalChannels]; 
TEXT.PnN = TEXT.PnS
TEXT.DATATYPE = 'F'; 
writeFCS(exportname, ResultsArray, TEXT);
