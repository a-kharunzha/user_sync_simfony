<?php

namespace App\Form;

use Symfony\Component\Form\FormBuilderInterface;
class ProfileFormType extends RegistrationFormType
{
    public function buildForm(FormBuilderInterface $builder, array $options)
    {
        parent::buildForm($builder, $options);
        // remove
        $builder->remove('plainPassword');
    }
}
