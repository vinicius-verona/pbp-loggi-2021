# **Input Directory**
> This directory is used to store instances in JSON format.
---

## **Used Directory Tree**
```
- input
 |- dev
    |- df-0
       |- instance.json

    |- df-1
    |- df-2
    |- .
    |- .
    |- .

 |- train
    |- df-0
       |- instance.json

    |- df-1
    |- df-2
    |- .
    |- .
    |- .
```
PS: In order to execute an instance, a distance matrix zip must be present on [../DistanceMatrix](../DistanceMatrix/)

---

## **Instance Schema**
Accordingly to [Loggi Benchmark for Urban Deliveries (BUD)](https://github.com/loggi/loggibud) instance schema, all instances must be according to the following example.

### **CVRP Instance Input**
```json
{
  // Name of the specific instance.
  "name": "rj-0-cvrp-0",

  // Hub coordinates, where the vehicles originate.
  "origin": {
    "lng": -42.0,
    "lat": -23.0
  },

  // The capacity (sum of sizes) of every vehicle.
  "vehicle_capacity": 120,

  // The deliveries that should be routed.
  "deliveries": [
    {
      // Unique delivery id.
      "id": "4943245fb66541edaf54f4e3aaed188a",

      // Delivery destination coordinates.
      "point": {
        "lng": -43.12589115884953,
        "lat": -22.89585186478512
      },

      // Size of the delivery.
      "size": 2
    }
    // ...
  ]
}
```
### **CVRP Output**
```json
{
  // Name of the specific instance.
  "name": "rj-0-cvrp-0",
  
  // Solution vehicles.
  "vehicles": [
    {
      // Vehicle origin (should be the same on CVRP solutions).
      "origin": {
        "lng": -43.374124642209765, 
        "lat": -22.790683484127058
      }, 
      // List of deliveries in the vehicle.
      "deliveries": [
        {
          "id": "54b10d6d-2ef7-4a69-a9f7-e454f81cdfd2",
          "point": {
            "lng": -43.44893966650845, 
            "lat": -22.742762573031424
          },
          "size": 8
        }
        // ...
      ]
    }
    // ...
  ]
}
```
---