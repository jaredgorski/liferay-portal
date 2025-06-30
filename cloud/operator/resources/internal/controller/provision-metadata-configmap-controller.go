package controller

import (
	"context"
	"fmt"
	"regexp"
	"strings"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/apimachinery/pkg/selection"
	labelutil "k8s.io/kubernetes/pkg/util/labels"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	logf "sigs.k8s.io/controller-runtime/pkg/log"
	"sigs.k8s.io/controller-runtime/pkg/predicate"
)

func GetProvisionMetadataConfigMapSelector() labels.Selector {
	isProvisionMetadataType, _ := labels.NewRequirement(
		MetadataTypeLabelKey,
		selection.Equals,
		[]string{MetadataTypeLabelValueProvision},
	)
	isSource, _ := labels.NewRequirement(
		IsSyncedCopyLabelKey,
		selection.DoesNotExist,
		[]string{},
	)

	return labels.NewSelector().Add(
		*isProvisionMetadataType,
		*isSource,
	)
}

func (r *ProvisionMetadataConfigMapController) Reconcile(
	ctx context.Context,
	req ctrl.Request,
) (ctrl.Result, error) {
	log := logf.FromContext(ctx)

	cm := &corev1.ConfigMap{}

	if err := r.Get(ctx, req.NamespacedName, cm); err != nil {
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}

	dxpNamespaceName := cm.GetNamespace()
	virtualInstanceId := cm.GetLabels()[VirtualInstanceIdLabelKey]

	defaultNamespaceName, err := getExtensionNamespaceName(dxpNamespaceName, virtualInstanceId, DefaultApplicationAlias)

	if err != nil {
		log.Error(
			err,
			"Failed to create label requirement to query default extension Namespace by virtualInstanceId",
			"virtualInstanceId",
			virtualInstanceId,
		)

		return ctrl.Result{}, err
	}


	defaultNamespace := &corev1.Namespace{}

	if err := r.Get(ctx, client.ObjectKey{Name: defaultNamespaceName}, defaultNamespace); err != nil {
		log.Error(
			err,
			"Failed to get default extension Namespace for virtualInstanceId",
			"virtualInstanceId",
			virtualInstanceId,
		)

		if apierrors.IsNotFound(err) {
			log.Info("Default extension Namespace not found for virtualInstanceId. Creating.")

			defaultNamespace.Name = defaultNamespaceName

			defaultNamespaceLabels := map[string]string{}
			defaultNamespaceLabels = labelutil.AddLabel(defaultNamespaceLabels, DXPNamespaceLabelKey, dxpNamespaceName)
			defaultNamespaceLabels = labelutil.AddLabel(defaultNamespaceLabels, ManagedByLabelKey, ManagedByLabelValueLiferayOperator)
			defaultNamespaceLabels = labelutil.AddLabel(defaultNamespaceLabels, VirtualInstanceIdLabelKey, virtualInstanceId)

			defaultNamespace.SetLabels(defaultNamespaceLabels)

			_ = r.Create(ctx, defaultNamespace)

			return ctrl.Result{}, nil
		}

		return ctrl.Result{}, err
	}

	return ctrl.Result{}, nil
}

func (r *ProvisionMetadataConfigMapController) SetupWithManager(mgr ctrl.Manager) error {
	selector := GetProvisionMetadataConfigMapSelector()
	labelSelector, err := metav1.ParseToLabelSelector(selector.String())
	predicate, err := predicate.LabelSelectorPredicate(*labelSelector)

	if err != nil {
		return err
	}

	return ctrl.NewControllerManagedBy(
		mgr,
	).For(
		&corev1.ConfigMap{},
	).Named(
		"ProvisionMetadataConfigMapController",
	).WithEventFilter(
		predicate,
	).Complete(
		r,
	)
}

type ProvisionMetadataConfigMapController struct {
	client.Client
}
