regions:
  900:
    regionid: 900
    regioncode: custom
    regionname: My Region
    nodes:
      - name: 900a
        regionid: 900
        hostname: ${DERP_HOSTNAME}
        ipv4: ${DERP_SERVER_PUBLIC_IP}