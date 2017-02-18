# ubuntu_auto
Generate Ubuntu Auto Install ISO image from offical Ubuntu ISO image

usage:

1.edit cfg.sh

  a.iscript_uri: script uri which will be executed when install finished, can be blank, default script name is "latecmd.sh")
  
  b.you may need to edit preseed.base, change location/time zone or others
  
2.run ./makeiso.sh




tested:

ubuntu server 16.04.1
