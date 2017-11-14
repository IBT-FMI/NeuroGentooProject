Amazon Webservices
==================

Images
-------

* <http://www.idevelopment.info/data/AWS/AWS_Tips/AWS_Management/AWS_10.shtml>
* `app-admin/ec2-ami-tools`
* `ec2-bundle-image`
* It seems like we have to create a raw-image like in sciencecloud, 
	which then gets compressed (at least).
* `ec2-bundle-vol` bundles a directory, which is more to our taste.
* Do we receive kernel and initramfs or do we have to build this ourselves?
	We can specify something with 
	```
	--kernel ID                  Id of the default kernel to launch the AMI with.
	--ramdisk ID                 Id of the default ramdisk to launch the AMI with.
	```

Gentoo
-------

```
# Michael Orlitzky <mjo@gentoo.org> (07 Jan 2017)
# This package has some dangerous quality and security issues, but
# people may still find it useful. It is masked to prevent accidental
# use. See bugs 603346 and 604998 for more information.
app-admin/amazon-ec2-init
```
