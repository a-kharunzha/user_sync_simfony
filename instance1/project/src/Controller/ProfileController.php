<?php

namespace App\Controller;

use App\Entity\User;
use App\Form\ProfileFormType;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\RedirectResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Session\SessionInterface;
use Symfony\Component\Routing\Annotation\Route;
use Symfony\Component\Security\Core\Encoder\UserPasswordEncoderInterface;

class ProfileController extends AbstractController
{
    /**
     * @Route("/profile", name="profile")
     */
    public function index(Request $request, SessionInterface $session)
    {
        // usually you'll want to make sure the user is authenticated first
        $this->denyAccessUnlessGranted('IS_AUTHENTICATED_FULLY');
        //
        $session->start();
        $message = $session->remove('profile_message');
        // returns your User object, or null if the user is not authenticated
        // use inline documentation to tell your editor your exact User class
        /** @var User $user */
        $user = $this->getUser();
        // create form for editing

        $form = $this->createForm(ProfileFormType::class, $user);
        $form->handleRequest($request);
        //
        if ($form->isSubmitted() && $form->isValid()) {
            $entityManager = $this->getDoctrine()->getManager();
            $entityManager->persist($user);
            $entityManager->flush();
            $session->set('profile_message','Profile data is updated');
            return new RedirectResponse('profile');
        }
        // view
        return $this->render('profile/profile.html.twig', [
            'controller_name' => 'ProfileController',
            'user'=>$user,
            'profileForm'=>$form->createView(),
            'message'=>$message
        ]);
    }
}
