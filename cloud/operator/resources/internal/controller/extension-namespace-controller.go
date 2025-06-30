package controller

import (
	"context"
	"fmt"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/apimachinery/pkg/selection"
	labelutil "k8s.io/kubernetes/pkg/util/labels"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	logf "sigs.k8s.io/controller-runtime/pkg/log"
	"sigs.k8s.io/controller-runtime/pkg/predicate"
)

func GetExtensionNamespaceSelector() labels.Selector {
	hasDXPNamespace, _ := labels.NewRequirement(
		DXPNamespaceLabelKey,
		selection.Exists,
		[]string{},
	)

	return labels.NewSelector().Add(*hasDXPNamespace)
}

func (r *ExtensionNamespaceController) Reconcile(
	ctx context.Context,
	req ctrl.Request,
) (ctrl.Result, error) {
	ns := &corev1.Namespace{}

	if err := r.Get(ctx, client.ObjectKey{Name: req.Name}, ns); err != nil {
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}

	nsLabels := ns.GetLabels()
	dxpNamespace := nsLabels[DXPNamespaceLabelKey]
	virtualInstanceId := nsLabels[VirtualInstanceIdLabelKey]

	dxpMetadataConfigMap, err := r.fetchSourceDXPConfigMap(ctx, dxpNamespace, virtualInstanceId)

	if err != nil {
		return ctrl.Result{}, err
	}

	dxpMetadataConfigMapCopyToSync := dxpMetadataConfigMap.DeepCopy()
	dxpMetadataConfigMapCopyToSync.ObjectMeta = metav1.ObjectMeta{
		Name: dxpMetadataConfigMap.Name,
		Namespace: ns.Name,
		Labels: labelutil.CloneAndAddLabel(
			dxpMetadataConfigMap.Labels,
			IsSyncedCopyLabelKey,
			"true",
		),
	}

	_ = r.Create(ctx, dxpMetadataConfigMapCopyToSync)

	return ctrl.Result{}, nil
}

func (r *ExtensionNamespaceController) SetupWithManager(mgr ctrl.Manager) error {
	selector := GetExtensionNamespaceSelector()
	labelSelector, err := metav1.ParseToLabelSelector(selector.String())
	predicate, err := predicate.LabelSelectorPredicate(*labelSelector)

	if err != nil {
		return err
	}

	return ctrl.NewControllerManagedBy(
		mgr,
	).For(
		&corev1.Namespace{},
	).Named(
		"ExtensionNamespaceController",
	).WithEventFilter(
		predicate,
	).Complete(
		r,
	)
}

func (r *ExtensionNamespaceController) fetchSourceDXPConfigMap(ctx context.Context, dxpNamespace string, virtualInstanceId string) (*corev1.ConfigMap, error) {
	log := logf.FromContext(ctx)

	dxpNamespaceConfigMapList := &corev1.ConfigMapList{}

	virtualInstanceIdLabelRequirement, err := labels.NewRequirement(
		VirtualInstanceIdLabelKey,
		selection.Equals,
		[]string{virtualInstanceId},
	)

	if err != nil {
		log.Error(
			err,
			"Failed to create label requirement to query DXP metadata ConfigMap by virtualInstanceId",
			"dxpNamespace",
			dxpNamespace,
			"virtualInstanceId",
			virtualInstanceId,
		)

		return &corev1.ConfigMap{}, err
	}

	listOpts := []client.ListOption{
		client.InNamespace(dxpNamespace),
		client.MatchingLabelsSelector{
			Selector: GetDXPMetadataConfigMapSelector().Add(
				*virtualInstanceIdLabelRequirement,
			),
		},
	}

	if err := r.List(ctx, dxpNamespaceConfigMapList, listOpts...); err != nil {
		log.Error(
			err,
			"Failed to list DXP metadata ConfigMaps for virtualInstanceId",
			"dxpNamespace",
			dxpNamespace,
			"virtualInstanceId",
			virtualInstanceId,
		)

		return &corev1.ConfigMap{}, err
	}

	if len(dxpNamespaceConfigMapList.Items) == 0 {
		err := fmt.Errorf("Empty list")

		log.Error(
			err,
			"Failed to list DXP metadata ConfigMaps for virtualInstanceId",
			"dxpNamespace",
			dxpNamespace,
			"virtualInstanceId",
			virtualInstanceId,
		)

		return &corev1.ConfigMap{}, err
	}

	return &dxpNamespaceConfigMapList.Items[0], nil
}

type ExtensionNamespaceController struct {
	client.Client
}
