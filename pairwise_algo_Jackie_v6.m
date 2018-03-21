%same count, same totalrun, 5k (22) vs 18k (22a) for method 0
%auction 58 data is wrong

clear;
%%%%%%%%%%% Data inputs %%%%%%%%%%%
%%%%%%%%%%%             %%%%%%%%%%%
Data = xlsread('Auction58_Correct.xlsx');
Adj = 0;
USPOP = 252556719;
% no dummy is 0, with dummy is 1, with number of owner is 2
% trying number 3 with actual cross auction geocomp
MethodWithDummy = 0;
beta1min = 10;
beta1max = 30;
interval1 = 1;
beta2min = 1;
beta2max = 1;
interval2 = 1;

% License Data
Lat = Data(:,3+Adj); % Latitude of license location
Lat = deg2rad(Lat); % Converting to radians
Long = Data(:,4+Adj); % Longitude of license location
Long = deg2rad(Long); % Converting to radians
Pop = Data(:,5+Adj); % Population of license location
LicenseElig = Data(:,6+Adj); % Eligibility required for license
LicenseElig = LicenseElig(LicenseElig>0); % Making sure there are no NaN cells
LicenseOwned = Data(:,8+Adj); % Number of PreOwned Licenses for each bidder
TotalLicenseOwned = sum(LicenseOwned(LicenseOwned>=0)) % Making sure there are no NaN cells
NumLicenseTotal = length(Lat); % Total number of licenses (including preowned)
NumLicenseWithin = length(LicenseElig); % Total number of licenses sold in auction
NumLicenseCross = NumLicenseTotal - NumLicenseWithin; % Total number of preowned licenses

% Bidder Data
Elig = Data(:,12); % Eligibility for each bidder
Elig = Elig(Elig>0); % Making sure there are no NaN
IndexStart = Data(:,10);
IndexStart = IndexStart(IndexStart>0);
IndexEnd = Data(:,11);
IndexEnd = IndexEnd(IndexEnd>0);
ELIG = sum(Elig);

% IndexPure for non-repeated indexes
IndexPure = zeros(length(Elig),2);
% Index for repeated indexes
Index = zeros(NumLicenseWithin,1);
NumOwner = length(IndexPure);

%Creation of index pure
for k = 1:length(Elig)
    IndexPure(k,1) = IndexStart(k);
    IndexPure(k,2) = IndexEnd(k);
end

counter = 1;

%Creation of Index
for l = 1:length(Elig)
    NumLicEachBidder = IndexPure(l,2)-IndexPure(l,1)+1;
    for m = 1:NumLicEachBidder
        Index(counter,1) = IndexPure(l,1);
        Index(counter,2) = IndexPure(l,2);
        counter = counter +1;
    end
end

%%%%%%%%%%%%% Matrix Construction   %%%%%%%%%%%%%%
%%%%%%%%%%%%%                       %%%%%%%%%%%%%%
% PopMatrix construction
PopMatrix = meshgrid(Pop)';
for g=1:NumLicenseTotal
    PopMatrix(g,g)=0;
end

DistanceCheck = zeros(NumLicenseTotal);
%GeoMatrix Construction
GeoMatrix = zeros(NumLicenseTotal);
for k=1:NumLicenseTotal
   for l=1:NumLicenseTotal
       %Can change power/delta here
       DistanceNum = haversine(Lat(k),Long(k),Lat(l),Long(l));
       DistanceSquared = power(DistanceNum,2);
       DistanceCheck(k,l) = DistanceNum;
       if DistanceNum == 0
           GeoMatrix(k,l) =0;
       else
           GeoMatrix(k,l) = Pop(k).*Pop(l)./DistanceSquared;
       end

   end
end

for m=1:NumLicenseTotal
    GeoMatrix(m,m)=0;
end

if MethodWithDummy >0
    BigSmallMatrix = Data(:,14:14+NumOwner-1);
end


%%%%%%%%%%%%%%% Implementing Equation Here      %%%%%%%%%%%%
%%%%%%%%%%%%%%% Will need to repeatedly perform %%%%%%%%%%%%
%%%%%%%%%%%%%%                                  %%%%%%%%%%%%
% Denom Array formed
%Denom = sum(GeoMatrix);

Numer = zeros(NumLicenseWithin);
for n=1:NumLicenseWithin
    Numer(n) = sum(GeoMatrix(Index(n,1):Index(n,2),n));
end

Denom = zeros(NumLicenseWithin);
for n=1:NumLicenseWithin
    Denom(n) = sum(GeoMatrix(:,n));
end
Denom = Denom(1:NumLicenseWithin,1)';

% Numer Array formed
Numer = Numer(:,1)';

%GeoComp by license formed
GeoCompj = zeros(1,NumLicenseWithin);
for p=1:NumLicenseWithin
    GeoCompj(p) = Pop(p).*Numer(p)./Denom(p);
end

GeoCompJ = zeros(1,NumOwner);
for q=1:NumOwner
    GeoCompJ(q) = sum(GeoCompj(IndexPure(q,1):IndexPure(q,2)));
end
GeoAvg = mean(GeoCompJ);
GeoStd = std(GeoCompJ);

Results = zeros(1000,4);

PopTotal = zeros(1,NumOwner);
for q=1:NumOwner
    PopTotal(q) = sum(Pop(IndexPure(q,1):IndexPure(q,2)));
end

PopAvg = mean(PopTotal);
PopStd = std(PopTotal);

EligPopTotal = zeros(1,NumOwner);
for q=1:NumOwner
    EligPopTotal(q) = Elig(q)/ELIG*sum(Pop(IndexPure(q,1):IndexPure(q,2)));
end
EligAvg = mean(EligPopTotal);
EligStd = std(EligPopTotal);

%%%%%%%%%% CrossAuctionGeoComp Testing Starts Here    %%%%%%%%%%%%
%%%%%%%%%%                                            %%%%%%%%%%%%
% manipulating LicenseOwned to deal with the problem of having 0 license
% owned
% OwnedIndexStart = NumLicenseWithin + LicenseOwnedIndex -LicenseOwned + 1 
% OwnedIndexEnd = NumLicenseWithin + LicenseOwnedIndex
% Note that if bidder has no license owned, LicenseOwnedIndex = 0. 

if MethodWithDummy == 3;
StartOwned = NumLicenseWithin;
EndOwned = 0;
LicenseOwnedIndexPure = zeros(length(LicenseOwned),2);
for n=1:length(LicenseOwned)
    if LicenseOwned(n)==0
        LicenseOwnedIndexPure(n,1) = 0;
        LicenseOwnedIndexPure(n,2) = 0;
    else
        EndOwned = NumLicenseWithin + sum(LicenseOwned(1:n));
        StartOwned = StartOwned+1;
        LicenseOwnedIndexPure(n,1) = StartOwned;
        LicenseOwnedIndexPure(n,2) = EndOwned;
        StartOwned = EndOwned;
    end
end

LicenseOwnedIndex = zeros(length(NumLicenseWithin),2);
Ucounter = 1;
for l = 1:length(LicenseOwned)
    NumLicEachBidder = IndexPure(l,2)-IndexPure(l,1)+1;
    if LicenseOwned(l) == 0;
        for m = 1:NumLicEachBidder
            LicenseOwnedIndex(Ucounter,1) = 0;
            LicenseOwnedIndex(Ucounter,2) = 0;
            Ucounter = Ucounter + 1;
        end
    else
        for m = 1:NumLicEachBidder
            LicenseOwnedIndex(Ucounter,1) = LicenseOwnedIndexPure(l,1);
            LicenseOwnedIndex(Ucounter,2) = LicenseOwnedIndexPure(l,2);
            Ucounter = Ucounter +1;
        end
    end
end

%%%% add this part into the loop %%%%%
CrossNumer = zeros(NumLicenseWithin);
for n=1:NumLicenseWithin
    if LicenseOwnedIndex(n,1) == 0;
        CrossNumer(n) = 0;
    else
    CrossNumer(n) = sum(GeoMatrix(LicenseOwnedIndex(n,1):LicenseOwnedIndex(n,2),n));
    end
end

% Numer Array formed
CrossNumer = CrossNumer(:,1)';

%GeoComp by license formed
CrossGeoCompj = zeros(1,NumLicenseWithin);
for p=1:NumLicenseWithin
    CrossGeoCompj(p) = Pop(p).*CrossNumer(p)./Denom(p);
end

CrossGeoCompJ = zeros(1,NumOwner);
for q=1:NumOwner
    CrossGeoCompJ(q) = sum(CrossGeoCompj(IndexPure(q,1):IndexPure(q,2)));
end

end % end CrossGeocomp stuff 
%%%%%%%%%%%                                   %%%%%%%%%%%%%%%
%%%%%%%%%%% Cross auction testing ends here   %%%%%%%%%%%%%%%




%%%%%%%%%%% Start of main loops  %%%%%%%%%%%%%%
%%%%%%%%%%%                     %%%%%%%%%%%%%%
%%%%%%%%%%%                     %%%%%%%%%%%%%%
NumberOfBeta1Guess = 0;
NumberOfBeta2Guess = 0;
 for Beta1=beta1min:interval1:beta1max;
     NumberOfBeta1Guess = NumberOfBeta1Guess + 1;
     Beta1Record(NumberOfBeta1Guess) = Beta1;
     Beta1Length = length(Beta1Record);
     for Beta2=beta2min:interval2:beta2max;
        NumberOfBeta2Guess = NumberOfBeta2Guess+1;
        count = 0;
        totalruns = 0;
        Score = 0;
        FailedSwaps = 0;
            %f = @(Index,Elig) Elig*PopJ+Beta1*GeoComp
        Beta2Record(NumberOfBeta2Guess) = Beta2;
        Beta2Length = length(Beta2Record);
    for a = 1:NumOwner-1
        for b = a+1:NumOwner
            Owner1 = IndexPure(a,:);
            Owner2 = IndexPure(b,:);
            Size1 = Owner1(2)-Owner1(1)+1;
            Size2 = Owner2(2)-Owner2(1)+1;
            Bidder1Elig = Elig(a);
            Bidder2Elig = Elig(b);
                for c = 1:Size1
                for d = 1:Size2
                    
                    totalruns = totalruns + 1; % total runs is number of loops ran
                    % k for bidder 1, l for bidder 2, k and l indicate the
                    % index of the cth license of owner a and dth license of
                    % owner b, 
                    k = IndexPure(a,1)+c-1; 
                    l = IndexPure(b,1)+d-1;
                   
                    %Elig Check
                    %Bidder1EligRecord(totalruns) = Bidder1Elig;
                    %Bidder2EligRecord(totalruns) = Bidder2Elig;
                    
                    License1Elig = LicenseElig(k);
                    License2Elig = LicenseElig(l);
                    
                    %Bidder1UsedElig = sum(LicenseElig(IndexPure(a,1):IndexPure(a,2)));
                    %Bidder2UsedElig = sum(LicenseElig(IndexPure(b,1):IndexPure(b,2)));
                    
                    %current elig minus elig being considered
                    Bidder1RemainingElig = Bidder1Elig-sum(LicenseElig(IndexPure(a,1):IndexPure(a,2)));
                    Bidder2RemainingElig = Bidder2Elig-sum(LicenseElig(IndexPure(b,1):IndexPure(b,2)));
                    
                    % SpareElig is the eligibility left after obtaining the
                    % swapped license. If <0, means swap should not be
                    % allowed. 
                    Bidder1SpareElig = Bidder1RemainingElig - License2Elig;
                    Bidder2SpareElig = Bidder2RemainingElig - License1Elig;
                    
                    %Bidder1RemainingEligRecord(totalruns) = Bidder1RemainingElig;
                    %Bidder2RemainingEligRecord(totalruns) = Bidder2RemainingElig;
                    
                    if ((Bidder1SpareElig >= 0) & (Bidder2SpareElig >=0))
                        count = count +1; % count is the number of swaps performed
          
                        %Bidder1SpareEligRecord(count) = Bidder1SpareElig;
                        %Bidder2SpareEligRecord(count) = Bidder2SpareElig;
                    
                        GeoMatrixTemp = GeoMatrix;
                        %Swapping of rows for geocomp
                        TempGeoRow1 = GeoMatrixTemp(k,:);
                        TempGeoRow2 = GeoMatrixTemp(l,:);
                        GeoMatrixTemp(k,:) = TempGeoRow2;
                        GeoMatrixTemp(l,:) = TempGeoRow1;

                        %Swapping of columns for geocomp
                        TempGeoCol1 = GeoMatrixTemp(:,k);
                        TempGeoCol2 = GeoMatrixTemp(:,l);
                        GeoMatrixTemp(:,k) = TempGeoCol2;
                        GeoMatrixTemp(:,l) = TempGeoCol1;

                        %Create temporary matrix for population column vector
                        PopTemp = Pop;
                        %Swapping of rows for pop
                        TempPopRow1 = PopTemp(k);
                        TempPopRow2 = PopTemp(l);
                        PopTemp(k) = TempPopRow2;
                        PopTemp(l) = TempPopRow1;
                        Pop=Pop(1:NumLicenseWithin,:);
                        PopTemp=PopTemp(1:NumLicenseWithin,:);

                           if MethodWithDummy >0
                            %Create temporary matrix for bigsmall column vector
                            BigSmallTemp = BigSmallMatrix;
                            %Swapping of rows for pop
                            TempBidRow1 = BigSmallTemp(k,:);
                            TempBidRow2 = BigSmallTemp(l,:);
                            BigSmallTemp(k,:) = TempBidRow2;
                            BigSmallTemp(l,:) = TempBidRow1;
                            end

                            %New initialization of New Numer, New Denom, New
                            %Geocompj 
                            NewNumer = Numer;
                            NewDenom = Denom;
                            NewGeoCompjTemp = GeoCompj;
                            NewGeoCompJTemp = GeoCompJ;
                            
                            if MethodWithDummy == 3;
                                NewCrossNumer= CrossNumer; 
                                NewCrossGeoCompjTemp=CrossGeoCompj; 
                                NewCrossGeoCompJTemp = CrossGeoCompJ;
                            end

                            %Adjust only the licenses of Owner 1 in terms of numer,
                            %denom, geocompj
                            for n=Owner1(1):Owner1(2)
                                NewNumer(n) = sum(GeoMatrixTemp(Index(n,1):Index(n,2),n));
                                NewDenom(n) = sum(GeoMatrixTemp(1:NumLicenseTotal,n));
                                NewGeoCompjTemp(n) = PopTemp(n).*NewNumer(n)./NewDenom(n);
                                if MethodWithDummy ==3;
                                    if LicenseOwnedIndex(n,1)==0;
                                        NewCrossNumer(n)=0;
                                    else
                                        NewCrossNumer(n) = sum(GeoMatrixTemp(LicenseOwnedIndex(n,1):LicenseOwnedIndex(n,2),n));
                                    end
                                        NewCrossGeoCompjTemp(n) = PopTemp(n).*NewCrossNumer(n)./NewDenom(n);
                                end
                            end
    
                            %Adjust only the licenses of Owner 2 in terms of numer,
                            %denom, geocompj
                            for n=Owner2(1):Owner2(2)
                                NewNumer(n) = sum(GeoMatrixTemp(Index(n,1):Index(n,2),n));
                                NewDenom(n) = sum(GeoMatrixTemp(1:NumLicenseTotal,n));
                                NewGeoCompjTemp(n) = PopTemp(n).*NewNumer(n)./NewDenom(n);
                                if MethodWithDummy == 3;
                                    if LicenseOwnedIndex(n,1)==0;
                                        NewCrossNumer(n)=0;
                                    else
                                        NewCrossNumer(n) = sum(GeoMatrixTemp(LicenseOwnedIndex(n,1):LicenseOwnedIndex(n,2),n));
                                    end
                                    NewCrossGeoCompjTemp(n) = PopTemp(n).*NewCrossNumer(n)./NewDenom(n);
                                end 
                            end

                            %Adjust Owner 1 and 2 in terms of GeoCompJ
                            NewGeoCompJTemp(a) =sum(NewGeoCompjTemp(IndexPure(a,1):IndexPure(a,2)));
                            NewGeoCompJTemp(b) =sum(NewGeoCompjTemp(IndexPure(b,1):IndexPure(b,2)));
                            
                            
                            if MethodWithDummy == 3;
                                NewCrossGeoCompJTemp(a) =sum(NewCrossGeoCompjTemp(IndexPure(a,1):IndexPure(a,2)));
                                NewCrossGeoCompJTemp(b) =sum(NewCrossGeoCompjTemp(IndexPure(b,1):IndexPure(b,2)));
                            end 

                            %Making Comparisons, stating new variables
                            Bidder1OrigGC = GeoCompJ(a);
                            Bidder2OrigGC = GeoCompJ(b);
                            Bidder1NewGC = NewGeoCompJTemp(a);
                            Bidder2NewGC = NewGeoCompJTemp(b);
                            Bidder1OldPop = sum(Pop(IndexPure(a,1):IndexPure(a,2)));
                            Bidder2OldPop = sum(Pop(IndexPure(b,1):IndexPure(b,2)));
                            Bidder1NewPop = sum(PopTemp(IndexPure(a,1):IndexPure(a,2)));
                            Bidder2NewPop = sum(PopTemp(IndexPure(b,1):IndexPure(b,2)));
                            
                            
                            
                            if MethodWithDummy == 3;
                                Bidder1OrigCrossGC = CrossGeoCompJ(a);
                                Bidder2OrigCrossGC = CrossGeoCompJ(b);
                                Bidder1NewCrossGC = NewCrossGeoCompJTemp(a);
                                Bidder2NewCrossGC = NewCrossGeoCompJTemp(b);
                            end 
                            
                            
                        if MethodWithDummy == 0 % without dummy (ie closed auction)
                            Bidder1OldValue= Bidder1Elig/ELIG.*Bidder1OldPop+Beta1.*Bidder1OrigGC;
                            Bidder2OldValue= Bidder2Elig/ELIG.*Bidder2OldPop+Beta1.*Bidder2OrigGC;
                            Bidder1NewValue= Bidder1Elig/ELIG.*Bidder1NewPop+Beta1.*Bidder1NewGC;
                            Bidder2NewValue= Bidder2Elig/ELIG.*Bidder2NewPop+Beta1.*Bidder2NewGC;
                        end
                    
                        if MethodWithDummy == 1 % with dummy
                            Bidder1OldBig = sum(BigSmallMatrix(IndexPure(a,1):IndexPure(a,2),a))/NumLicenseWithin;
                            Bidder2OldBig = sum(BigSmallMatrix(IndexPure(b,1):IndexPure(b,2),b))/NumLicenseWithin; 
                            Bidder1NewBig = sum(BigSmallTemp(IndexPure(a,1):IndexPure(a,2),a))/NumLicenseWithin; 
                            Bidder2NewBig = sum(BigSmallTemp(IndexPure(b,1):IndexPure(b,2),b))/NumLicenseWithin;
                            Bidder1OldValue= Bidder1Elig/ELIG.*Bidder1OldPop+Beta1.*Bidder1OrigGC+Beta2.*Bidder1OldBig;
                            Bidder2OldValue= Bidder2Elig/ELIG.*Bidder2OldPop+Beta1.*Bidder2OrigGC+Beta2.*Bidder2OldBig;
                            Bidder1NewValue= Bidder1Elig/ELIG.*Bidder1NewPop+Beta1.*Bidder1NewGC+Beta2.*Bidder1NewBig;
                            Bidder2NewValue= Bidder2Elig/ELIG.*Bidder2NewPop+Beta1.*Bidder2NewGC+Beta2.*Bidder2NewBig;
                        end

                        if MethodWithDummy == 2 % using number of licenses owned
                            Bidder1OldBig = LicenseOwned(a)/TotalLicenseOwned*sum(BigSmallMatrix(IndexPure(a,1):IndexPure(a,2),a))/NumLicenseWithin;
                            Bidder2OldBig = LicenseOwned(b)/TotalLicenseOwned*sum(BigSmallMatrix(IndexPure(b,1):IndexPure(b,2),b))/NumLicenseWithin; 
                            Bidder1NewBig = LicenseOwned(a)/TotalLicenseOwned*sum(BigSmallTemp(IndexPure(a,1):IndexPure(a,2),a))/NumLicenseWithin; 
                            Bidder2NewBig = LicenseOwned(b)/TotalLicenseOwned*sum(BigSmallTemp(IndexPure(b,1):IndexPure(b,2),b))/NumLicenseWithin;
                            Bidder1OldValue= Bidder1Elig/ELIG.*Bidder1OldPop+Beta1.*Bidder1OrigGC+Beta2.*Bidder1OldBig;
                            Bidder2OldValue= Bidder2Elig/ELIG.*Bidder2OldPop+Beta1.*Bidder2OrigGC+Beta2.*Bidder2OldBig;
                            Bidder1NewValue= Bidder1Elig/ELIG.*Bidder1NewPop+Beta1.*Bidder1NewGC+Beta2.*Bidder1NewBig;
                            Bidder2NewValue= Bidder2Elig/ELIG.*Bidder2NewPop+Beta1.*Bidder2NewGC+Beta2.*Bidder2NewBig;
                        end
                       if MethodWithDummy == 3
                            Bidder1OldValue= Bidder1Elig/ELIG.*Bidder1OldPop+Beta1.*Bidder1OrigGC+Beta2.*Bidder1OrigCrossGC;
                            Bidder2OldValue= Bidder2Elig/ELIG.*Bidder2OldPop+Beta1.*Bidder2OrigGC+Beta2.*Bidder2OrigCrossGC;
                            Bidder1NewValue= Bidder1Elig/ELIG.*Bidder1NewPop+Beta1.*Bidder1NewGC+Beta2.*Bidder1NewCrossGC;
                            Bidder2NewValue= Bidder2Elig/ELIG.*Bidder2NewPop+Beta1.*Bidder2NewGC+Beta2.*Bidder2NewCrossGC;
                       end
                            if (Bidder1OldValue + Bidder2OldValue) >= (Bidder1NewValue + Bidder2NewValue)
                                Score = Score +1; 
                            end
                        else
                        FailedSwaps = FailedSwaps + 1;
                        
                    end % ending if eligible to swap
                end % ending d loop 
            end % ending c loop
        end % ending b loop
    end % ending a loop
    
    ScorePercent(Beta1Length,Beta2Length) = Score/count;

    end
 end
 
load handel
sound(y,Fs)
