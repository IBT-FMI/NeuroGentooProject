Amazon Webservices
==================

Images
-------

* <http://www.idevelopment.info/data/AWS/AWS_Tips/AWS_Management/AWS_10.shtml>
* <https://alestic.com/2009/06/ec2-ami-bundle/>
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

Proposal Description
--------------------

We intend to use AWS EC2-instances to test our generated EC2-images.
We therefore need to 






We are planning to instanciate a build-server and a distribution-server on EC2, where the former keeps the Gentoo flavours
up to date and the latter to distribute the images.
This approach has the benefit of using the high-performance build-server only for a small amount of time, whilst the
low-power and low-cost distribution-server runs permanently.

The builds are stored inside an EBS such that we can update them continuously.
After updating (or creation), ec2-bundle-vol generates EC2-images of these builds, which in turn get distributed by the distribution-server.

The first step is to set up the build-server. There are already some basics layed out for that part, but we hope to complete and further refine that process.
The distribution-server has to hold some logic for choosing the right image for the requests.
The completion of the distribution-server would conclude the project in this scope.
