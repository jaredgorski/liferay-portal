package controller

import ()

const (
	DefaultApplicationAlias = "default"
	DXPNamespaceLabelKey               = "lxc.liferay.com/dxp-namespace"
	IsSyncedCopyLabelKey                     = "cx.liferay.com/is-synced-copy"
	ManagedByLabelKey                  = "app.kubernetes.io/managed-by"
	ManagedByLabelValueLiferayOperator = "liferay-operator"
	MetadataTypeLabelKey               = "lxc.liferay.com/metadataType"
	MetadataTypeLabelValueDXP          = "dxp"
	MetadataTypeLabelValueProvision          = "ext-provision"
	VirtualInstanceIdLabelKey          = "dxp.lxc.liferay.com/virtualInstanceId"
)
