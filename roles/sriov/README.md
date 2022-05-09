# sriov

Create the maximum number of VFs a PF can support and bind half of them
to vfio driver and the rest to netdev

## Requirements

Minimum ansible version: 2.9.5

## Example Playbook

```yaml
- hosts: all
  vars:
    sriov_pf_name: enp175s0f0
  roles:
    - sriov

```

## License and Author

© 2021 Open Networking Foundation <support@opennetworking.org>

License: Apache-2.0
