package cache

import (
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/apimachinery/pkg/selection"
	"sigs.k8s.io/controller-runtime/pkg/cache"
	"sigs.k8s.io/controller-runtime/pkg/client"

	"github.com/liferay/liferay-portal/cloud/operator/internal/controller"
)

func GetCacheOptions() cache.Options {
	managedByLiferayOperator, _ := labels.NewRequirement(
		controller.ManagedByLabelKey,
		selection.Equals,
		[]string{controller.ManagedByLabelValueLiferayOperator},
	)
	hasVirtualInstanceId, _ := labels.NewRequirement(
		controller.VirtualInstanceIdLabelKey,
		selection.Exists,
		[]string{},
	)

	managedResourceSelector := labels.NewSelector().Add(
		*managedByLiferayOperator,
		*hasVirtualInstanceId,
	)

	return cache.Options{
		ByObject: map[client.Object]cache.ByObject{
			&corev1.ConfigMap{}: {
				Label: managedResourceSelector,
			},
			&corev1.Namespace{}: {
				Label: managedResourceSelector,
			},
		},
	}
}
