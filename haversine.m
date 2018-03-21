function dist=haversine(lat1,lon1,lat2,lon2)
% HAVERSINE_FORMULA.AWK - converted from AWK 
    dlat = lat2-lat1;
    dlon = lon2-lon1;
 
    a = (sin(dlat./2)).^2 + cos(lat1) .* cos(lat2) .* (sin(dlon./2)).^2;
    c = 2 .* asin(sqrt(a));
    dist = c*6372.8;
end