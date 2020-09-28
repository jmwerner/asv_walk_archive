from urllib.parse import urlencode
from urllib.request import Request, urlopen
import json

# https://github.com/mgd722/decode-google-maps-polyline/blob/master/polyline_decoder.py
# This function is free of any dependencies.
def decode_polyline(polyline_str):
    #Pass a Google Maps encoded polyline string; returns list of lat/lon pairs
    index, lat, lng = 0, 0, 0
    coordinates = []
    changes = {'latitude': 0, 'longitude': 0}

    # Coordinates have variable length when encoded, so just keep
    # track of whether we've hit the end of the string. In each
    # while loop iteration, a single coordinate is decoded.
    while index < len(polyline_str):
        # Gather lat/lon changes, store them in a dictionary to apply them later
        for unit in ['latitude', 'longitude']: 
            shift, result = 0, 0

            while True:
                byte = ord(polyline_str[index]) - 63
                index+=1
                result |= (byte & 0x1f) << shift
                shift += 5
                if not byte >= 0x20:
                    break

            if (result & 1):
                changes[unit] = ~(result >> 1)
            else:
                changes[unit] = (result >> 1)

        lat += changes['latitude']
        lng += changes['longitude']

        coordinates.append((lat / 100000.0, lng / 100000.0))

    return coordinates



# Origin and destination arguments found in a google maps browser
request_string = "http://maps.googleapis.com/maps/api/directions/json?origin=37.480255,-122.177361&destination=28.2129335,-80.5976773"

request = Request(request_string)
json_string = urlopen(request).read().decode()

data = json.loads(json_string)

route = data['routes'][0]

leg = data['routes'][0]['legs'][0]

all_points = []

# Loop over this
for i in range(0, len(leg['steps'])):
    step = leg['steps'][i]
    decoded_points = decode_polyline(step['polyline']['points'])
    if i != 0:
        del decoded_points[0]
    all_points += decoded_points


with open('route_points.csv', 'w') as fp:
    fp.write('\n'.join('%s,%s' % x for x in all_points))





    