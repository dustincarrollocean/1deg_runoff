% Example snapping of GlobalNEWS2 to JRA55 locations
clear, close all

addpath ~dmenemen/matlab

load GlobalNews_to_JRA55

% glon  GlobalNEWS2 longitude E (deg)
% glat  GlobalNEWS2 latitude N (deg)
% gQact GlobalNEWS2 actual discharge (km^3/yr)
% gDIN  GlobalNEWS2 load DIN (Mg/yr)
% gDIP  GlobalNEWS2 load DIP (Mg/yr)
% gDON  GlobalNEWS2 load DON (Mg/yr)
% gDOP  GlobalNEWS2 load DON (Mg/yr)
% gDOC  GlobalNEWS2 load DOC (Mg/yr)
% gDSi  GlobalNEWS2 load DSi (Mg/yr)
% gPN   GlobalNEWS2 load PN (Mg/yr)
% gPP   GlobalNEWS2 load PP (Mg/yr)
% gPOC  GlobalNEWS2 load POC (Mg/yr)
% gTSS  GlobalNEWS2 load TSS (Mg/yr)
% gDIC  DIC load TSS from Li et al and Suchet et al combined 
%       in GlobalNEWS (Mg/yr)

% jlat/jlon : latitude/longitude of jra55_do
% jra       : jra55_do year-2000 runoff km^3/yr

% gQact2jra : index of GlobalNEWS2 location
%             for each jra55_do location that

% find indices IX the jlat/jlon location on the jra55_do grid
lon=0.125:0.25:360; nx=length(lon);
lat=-89.875:0.25:90; ny=length(lat); 
[LAT LON]=meshgrid(lat,lon);
IX=jlat;
for i=1:length(jlat)
    IX(i)=find(LAT==jlat(i)&LON==jlon(i)); 
end

% Compute weights, that is, the ratio of jra55_do runoff volume relative to
% the GlobalNEWS2 location associated with each jra55_do location 
jraWeights=jra*0;
jraWeights=jra./gQact(gQact2jra);


% Projecct GlobalNEWS2 nutrients to JRA55 locations
pin = '/nobackup/hzhang1/forcing/jra55_do/river_runoff/';
pout='~dmenemen/forcing/jra55_do/GlobalNEWS/GlobalNEWS2_on_jra55v1.4.0/';

% conversion factors of gram to mol
gP_to_molP = 0.03228539149637;
gN_to_molN = 0.071394404106606;
gC_to_molC = 0.083259093974539;
gSi_to_molSi = 0.03560556158872;

FLD_sum = [];
for yr=1991:2023
    fin=[pin 'jra55_do_runoff_' int2str(yr)];
    loy=365;
    if mod(yr,4)==0, loy=366; end
    for dy=1:loy, disp([yr dy])
        try
            Jravol=readbin(fin,[nx ny],1,'real*4',dy-1);
        catch
            continue
        end
        for f={'DIN','DIP','DON','DOP','DOC','DSi','PN','PP','POC','TSS','DIC'}
        %for f={'DIC'}
           fout=[pout f{1} '_' int2str(yr)];
            eval(['fld=g' f{1} ';'])
            FLD=0*LAT;
            %FLD(IX)=fld(gQact2jra).*jraWeights;
            GN_conc = fld(gQact2jra)./gQact(gQact2jra)./1e9.*1e6;%GlobalNEWS concentration g m-3
            GN_conc(gQact(gQact2jra) == 0) = 0; % mask division by zero
            FLD(IX) = GN_conc.*Jravol(IX);%Flux in g m-2 s-1
            % result in g m-2 s-1
            % 1e9 conversion from km-3 to m-3
            % 1e6 conversion from Mg to g
            % Following conditions are to convert g to mmol
            	if  endsWith(f{1},"N") == 1
            		FLD(IX) = FLD(IX).*gN_to_molN.*1e3;
            	elseif endsWith(f{1},"P") == 1
            		FLD(IX) = FLD(IX).*gP_to_molP.*1e3;
            	elseif endsWith(f{1},"C") == 1
            		FLD(IX) = FLD(IX).*gC_to_molC.*1e3;
            	elseif endsWith(f{1},"Si") == 1
            		FLD(IX) = FLD(IX).*gSi_to_molSi.*1e3;            		
            	else %no C, N, P or Si
            		%do nothing: TSS remain in g m-2 s-1
            	end	
            writebin(fout,FLD,1,'real*4',dy-1);
            
            
                if  endsWith(f{1},"N") == 1
                    conv = 1./gN_to_molN;
                elseif endsWith(f{1},"P") == 1
                    conv = 1./gP_to_molP;
                elseif endsWith(f{1},"C") == 1
                    conv = 1./gC_to_molC;
                elseif endsWith(f{1},"Si") == 1
                    conv = 1./gSi_to_molSi;            		
                else %no C, N, P or Si
                    %do nothing: TSS remain in g m-2 s-1
                end	

%             FLD2GN_conc = FLD(IX) ./ Jravol(IX) .* conv;
%             scatter(GN_conc*1e3,FLD2GN_conc);hold on
%             
%             FLD_sum = cat(2,FLD_sum,FLD2GN_conc);
        end
    end
end

% for i =1:366
%     scatter(GN_conc*1e3,mean(FLD_sum,2));hold on
% end
% 
%             clf,plotland(.8*[1 1 1],12), hold on
%             max_norm = max(max([FLD_sum(IX)./366 GN_conc*1e3]));
%             for i=1:50
%                 tmp=FLD_sum(IX)./366./max_norm;
%                 ix=find(tmp>(i-1)/50&tmp<=i/50);
%                 if ~isempty(ix)
%                     plot(jlon(ix),jlat(ix),'ro','markersize',i+3)
%                 end
%               
%                 tmp=GN_conc*1e3./max_norm;
%                 ix=find(tmp>(i-1)/50&tmp<=i/50);
%                 if ~isempty(ix)
%                     plot(jlon(ix),jlat(ix),'b+','markersize',i+3)
%                 end
%             end
%             text(185,-50,['jra mean ' num2str(mean(FLD_sum(IX)./366,'omitnan')) ' '],'color','r')
%             text(185,-60,['gn mean ' num2str(mean(GN_conc*1e3)) ' '],'color','b')
