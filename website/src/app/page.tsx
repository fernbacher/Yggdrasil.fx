import BootSequence from "@/components/BootSequence";
import Navigation from "@/components/Navigation";
import HeroSection from "@/components/HeroSection";
import ShaderConsole from "@/components/ShaderConsole";
import GalleryViewer from "@/components/GalleryViewer";
import InstallPipeline from "@/components/InstallPipeline";
import Footer from "@/components/Footer";

export default function HomePage() {
  return (
    <>
      <BootSequence />
      <Navigation />
      <HeroSection />
      <ShaderConsole />
      <GalleryViewer />
      <InstallPipeline />
      <Footer />
    </>
  );
}
